"""Unit tests for LLM URL construction."""

from app.services.llm_service import chat_completions_url


def test_chat_completions_url_with_v1_suffix():
    assert chat_completions_url("https://api.example.com/v1") == (
        "https://api.example.com/v1/chat/completions"
    )


def test_chat_completions_url_without_v1_suffix():
    assert chat_completions_url("https://api.example.com") == (
        "https://api.example.com/v1/chat/completions"
    )


def test_chat_completions_url_trailing_slash():
    assert chat_completions_url("https://api.example.com/v1/") == (
        "https://api.example.com/v1/chat/completions"
    )
