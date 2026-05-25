import os
import re
import json
import tempfile

import fitz  # pymupdf
from groq import Groq
from docx import Document
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pathlib import Path
from pptx import Presentation
from dotenv import load_dotenv


# ── ENV ───────────────────────────────────────────────────────────────────────
load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY is missing in environment variables")


# ── APP ──────────────────────────────────────────────────────────────────────
app = FastAPI(title="StudyMate AI", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_BYTES = 20 * 1024 * 1024  # 20 MB


EXTENSION_MAP = {
    ".pdf": "pdf",
    ".pptx": "pptx",
    ".docx": "docx",
}

CONTENT_TYPE_MAP = {
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
}


# ── PARSERS ──────────────────────────────────────────────────────────────────
def _parse_pdf(path: str) -> str:
    doc = fitz.open(path)
    pages = []
    for i, page in enumerate(doc):
        text = page.get_text()
        if text.strip():
            pages.append(f"[Страница {i + 1}]\n{text}")
    return "\n\n".join(pages)


def _parse_pptx(path: str) -> str:
    prs = Presentation(path)
    slides = []

    for i, slide in enumerate(prs.slides):
        texts = [
            para.text.strip()
            for shape in slide.shapes
            if shape.has_text_frame
            for para in shape.text_frame.paragraphs
            if para.text.strip()
        ]

        if texts:
            slides.append(f"[Слайд {i + 1}]\n" + "\n".join(texts))

    return "\n\n".join(slides)


def _parse_docx(path: str) -> str:
    doc = Document(path)
    parts = [p.text.strip() for p in doc.paragraphs if p.text.strip()]

    for table in doc.tables:
        for row in table.rows:
            row_text = " | ".join(
                c.text.strip() for c in row.cells if c.text.strip()
            )
            if row_text:
                parts.append(row_text)

    return "\n\n".join(parts)


PARSERS = {
    "pdf": _parse_pdf,
    "pptx": _parse_pptx,
    "docx": _parse_docx,
}


# ── HELPERS ──────────────────────────────────────────────────────────────────
def _clean(text: str) -> str:
    text = re.sub(r"\x00", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text.strip()


def _resolve_type(content_type: str, filename: str) -> str | None:
    if content_type in CONTENT_TYPE_MAP:
        return CONTENT_TYPE_MAP[content_type]
    return EXTENSION_MAP.get(Path(filename).suffix.lower())


def _parse_file(data: bytes, filename: str, content_type: str) -> tuple[str, str]:
    file_type = _resolve_type(content_type, filename)

    if not file_type:
        raise HTTPException(422, "Поддерживаются только PDF, PPTX, DOCX")

    with tempfile.NamedTemporaryFile(suffix=f".{file_type}", delete=False) as tmp:
        tmp.write(data)
        tmp_path = tmp.name

    try:
        text = _clean(PARSERS[file_type](tmp_path))
    except Exception as e:
        raise HTTPException(500, f"Ошибка парсинга: {e}")
    finally:
        os.unlink(tmp_path)

    if not text:
        raise HTTPException(422, "Документ пустой или не содержит текста")

    return text, file_type


# ── ROUTES ───────────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/api/upload")
async def upload(file: UploadFile = File(...)):
    data = await file.read()

    if len(data) > MAX_BYTES:
        raise HTTPException(413, "Файл больше 20 МБ")

    text, file_type = _parse_file(
        data,
        file.filename or "",
        file.content_type or "",
    )

    return {
        "filename": file.filename,
        "file_type": file_type,
        "char_count": len(text),
        "preview": text[:500],
        "text": text,
    }


@app.post("/api/summary")
async def summary(file: UploadFile = File(...)):
    data = await file.read()

    if len(data) > MAX_BYTES:
        raise HTTPException(413, "Файл больше 20 МБ")

    text, file_type = _parse_file(
        data,
        file.filename or "",
        file.content_type or "",
    )

    prompt = f"""
Ты — учебный ассистент. Сделай структурированный конспект:

## 📌 Тема
Одно предложение

## 🔑 Ключевые тезисы
5–7 пунктов

## 📝 Резюме
3–4 предложения

## ❓ Вопросы
3 вопроса

Материал:
{text[:12000]}
"""

    try:
        client = Groq(api_key=GROQ_API_KEY)
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
        )
        summary_text = response.choices[0].message.content
    except Exception as e:
        raise HTTPException(500, f"Groq API error: {e}")

    return {
        "filename": file.filename,
        "file_type": file_type,
        "char_count": len(text),
        "summary": summary_text,
    }


@app.post("/api/flashcards")
async def flashcards(file: UploadFile = File(...)):
    data = await file.read()

    if len(data) > MAX_BYTES:
        raise HTTPException(413, "Файл больше 20 МБ")

    text, file_type = _parse_file(
        data,
        file.filename or "",
        file.content_type or "",
    )

    prompt = f"""
Создай 7 флэшкарточек.

Ответ строго JSON массив:
[
  {{"front": "...", "back": "..."}}
]

Материал:
{text[:10000]}
"""

    try:
        client = Groq(api_key=GROQ_API_KEY)

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": prompt}],
        )

        raw = response.choices[0].message.content
        cards = json.loads(raw)

    except Exception as e:
        raise HTTPException(500, f"Groq API error: {e}")

    return {
        "filename": file.filename,
        "file_type": file_type,
        "count": len(cards),
        "flashcards": cards,
    }