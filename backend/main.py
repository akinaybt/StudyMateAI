import os
import re
import tempfile
import json
import uuid

import fitz  # pymupdf
from docx import Document
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from pathlib import Path
from pptx import Presentation

app = FastAPI(title="StudyMate AI", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
# ── ENV ───────────────────────────────────────────────────────────────────────
load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY is missing in environment variables")

MAX_DOC_BYTES   = 20 * 1024 * 1024
MAX_AUDIO_BYTES = 25 * 1024 * 1024

AUDIO_EXTENSIONS = {".mp3", ".mp4", ".wav", ".m4a", ".ogg", ".webm", ".flac"}

EXTENSION_MAP = {".pdf": "pdf", ".pptx": "pptx", ".docx": "docx"}
CONTENT_TYPE_MAP = {
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation": "pptx",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx",
}

# ── хранилище текстов в памяти ────────────────────────────────────────────────
# { document_id: { "filename": str, "file_type": str, "text": str } }
storage: dict = {}


# ── парсеры ───────────────────────────────────────────────────────────────────

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
            row_text = " | ".join(c.text.strip() for c in row.cells if c.text.strip())
            if row_text:
                parts.append(row_text)
    return "\n\n".join(parts)


PARSERS = {"pdf": _parse_pdf, "pptx": _parse_pptx, "docx": _parse_docx}


def _clean(text: str) -> str:
    text = re.sub(r"\x00", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = re.sub(r"[ \t]{2,}", " ", text)
    return text.strip()


def _resolve_doc_type(content_type: str, filename: str) -> str | None:
    if content_type in CONTENT_TYPE_MAP:
        return CONTENT_TYPE_MAP[content_type]
    return EXTENSION_MAP.get(Path(filename).suffix.lower())


def _parse_file(data: bytes, filename: str, content_type: str) -> tuple[str, str]:
    file_type = _resolve_doc_type(content_type, filename)
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
        raise HTTPException(422, "Не удалось извлечь текст — документ пустой или отсканирован")

    return text, file_type


# ── AI helpers ────────────────────────────────────────────────────────────────

def _generate_summary(text: str) -> str:
    prompt = f"""Ты — учебный ассистент. Проанализируй материал и создай структурированный конспект:

## 📌 Тема
Одно предложение — о чём этот материал.

## 🔑 Ключевые тезисы
5-7 самых важных пунктов (каждый 1-2 предложения).

## 📝 Резюме
Краткое резюме в 3-4 предложения.

## ❓ Вопросы для самопроверки
3 вопроса по материалу.

Материал:
{text[:12000]}"""

    client = Groq(api_key=GROQ_API_KEY)
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content


def _generate_flashcards(text: str) -> list:
    prompt = f"""Ты — учебный ассистент. Создай 10 флэшкарточек по материалу.

Ответь СТРОГО в формате JSON, без markdown, без пояснений:
{{"flashcards": [{{"front": "Вопрос или термин", "back": "Ответ или определение"}}]}}

Материал:
{text[:10000]}"""

    client = Groq(api_key=GROQ_API_KEY)
    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
    )
    parsed = json.loads(response.choices[0].message.content)
    return parsed.get("flashcards", [])


def _transcribe_audio(data: bytes, filename: str) -> str:
    suffix = Path(filename).suffix.lower() or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(data)
        tmp_path = tmp.name
    try:
        client = Groq(api_key=GROQ_API_KEY)
        with open(tmp_path, "rb") as audio_file:
            transcription = client.audio.transcriptions.create(
                file=(filename, audio_file),
                model="whisper-large-v3-turbo",
                response_format="text",
            )
        return transcription if isinstance(transcription, str) else transcription.text
    except Exception as e:
        raise HTTPException(500, f"Ошибка транскрипции: {e}")
    finally:
        os.unlink(tmp_path)


# ── эндпоинты ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok"}


# ШАГ 1 — загрузка документа, возвращает document_id
@app.post("/api/upload")
async def upload(file: UploadFile = File(...)):
    """Загружает документ, парсит текст, сохраняет в памяти. Возвращает document_id."""
    data = await file.read()
    if len(data) > MAX_DOC_BYTES:
        raise HTTPException(413, "Файл больше 20 МБ")

    text, file_type = _parse_file(data, file.filename or "", file.content_type or "")

    doc_id = str(uuid.uuid4())
    storage[doc_id] = {
        "filename": file.filename,
        "file_type": file_type,
        "text": text,
    }

    return {
        "document_id": doc_id,
        "filename": file.filename,
        "file_type": file_type,
        "char_count": len(text),
        "preview": text[:500],
    }


# ШАГ 2а — summary по document_id
@app.post("/api/summary/{document_id}")
async def summary(document_id: str):
    """Генерирует конспект по уже загруженному документу."""
    doc = storage.get(document_id)
    if not doc:
        raise HTTPException(404, "Документ не найден. Сначала загрузи файл через /api/upload")

    try:
        summary_text = _generate_summary(doc["text"])
    except Exception as e:
        raise HTTPException(500, f"Ошибка Groq API: {e}")

    return {
        "document_id": document_id,
        "filename": doc["filename"],
        "summary": summary_text,
    }


# ШАГ 2б — flashcards по document_id
@app.post("/api/flashcards/{document_id}")
async def flashcards(document_id: str):
    """Генерирует флэшкарточки по уже загруженному документу."""
    doc = storage.get(document_id)
    if not doc:
        raise HTTPException(404, "Документ не найден. Сначала загрузи файл через /api/upload")

    try:
        cards = _generate_flashcards(doc["text"])
    except Exception as e:
        raise HTTPException(500, f"Ошибка Groq API: {e}")

    return {
        "document_id": document_id,
        "filename": doc["filename"],
        "count": len(cards),
        "flashcards": cards,
    }


# ── аудио лекции ──────────────────────────────────────────────────────────────

@app.post("/api/lecture/transcribe")
async def lecture_transcribe(file: UploadFile = File(...)):
    """Загружает аудио лекции и возвращает транскрипцию + document_id для дальнейшей обработки."""
    data = await file.read()
    if len(data) > MAX_AUDIO_BYTES:
        raise HTTPException(413, "Аудиофайл больше 25 МБ")

    filename = file.filename or "audio.wav"
    if Path(filename).suffix.lower() not in AUDIO_EXTENSIONS:
        raise HTTPException(422, f"Поддерживаются: {', '.join(AUDIO_EXTENSIONS)}")

    transcript = _transcribe_audio(data, filename)
    if not transcript.strip():
        raise HTTPException(422, "Не удалось распознать речь")

    # сохраняем транскрипт так же как документ — можно потом вызвать /api/summary/{id}
    doc_id = str(uuid.uuid4())
    storage[doc_id] = {
        "filename": filename,
        "file_type": "audio",
        "text": transcript,
    }

    return {
        "document_id": doc_id,
        "filename": filename,
        "char_count": len(transcript),
        "transcript": transcript,
    }


@app.post("/api/lecture/summary")
async def lecture_summary(file: UploadFile = File(...)):
    """Загружает аудио → транскрипция → конспект. Всё в одном запросе."""
    data = await file.read()
    if len(data) > MAX_AUDIO_BYTES:
        raise HTTPException(413, "Аудиофайл больше 25 МБ")

    filename = file.filename or "audio.wav"
    if Path(filename).suffix.lower() not in AUDIO_EXTENSIONS:
        raise HTTPException(422, f"Поддерживаются: {', '.join(AUDIO_EXTENSIONS)}")

    transcript = _transcribe_audio(data, filename)
    if not transcript.strip():
        raise HTTPException(422, "Не удалось распознать речь")

    doc_id = str(uuid.uuid4())
    storage[doc_id] = {"filename": filename, "file_type": "audio", "text": transcript}

    try:
        summary_text = _generate_summary(transcript)
    except Exception as e:
        raise HTTPException(500, f"Ошибка генерации конспекта: {e}")

    return {
        "document_id": doc_id,
        "filename": filename,
        "transcript": transcript,
        "summary": summary_text,
    }