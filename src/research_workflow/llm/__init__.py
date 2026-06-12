"""Unified LLM inference clients for Anthropic and OpenAI.

Provides async chat models, batch APIs, file-based caching with LRU eviction,
and shared data models. Inspired by CAIS safety-tooling, adapted for our
anthropic>=0.86 / openai>=2.0 stack with no heavy deps.

Usage:
    from research_workflow.llm import (
        AnthropicChatModel,
        AnthropicBatch,
        OpenAIChatModel,
        OpenAIBatch,
        FileCache,
        Prompt,
        ChatMessage,
        MessageRole,
    )
"""

from research_workflow.llm.anthropic_client import AnthropicBatch, AnthropicChatModel
from research_workflow.llm.cache import FileCache
from research_workflow.llm.models import (
    ChatMessage,
    LLMParams,
    LLMResponse,
    MessageRole,
    Prompt,
    StopReason,
    Usage,
)
from research_workflow.llm.openai_client import OpenAIBatch, OpenAIChatModel

__all__ = [
    "AnthropicBatch",
    "AnthropicChatModel",
    "ChatMessage",
    "FileCache",
    "LLMParams",
    "LLMResponse",
    "MessageRole",
    "OpenAIBatch",
    "OpenAIChatModel",
    "Prompt",
    "StopReason",
    "Usage",
]
