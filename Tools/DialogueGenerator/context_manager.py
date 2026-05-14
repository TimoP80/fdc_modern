"""
Context Management System for Procedural Dialogue Generation
Implements hybrid short-term and long-term memory management
"""

from collections import deque
from datetime import datetime
from typing import List, Dict, Optional, Any
import json
import os


class ShortTermMemory:
    """Sliding window buffer for recent conversation history"""
    
    def __init__(self, max_turns: int = 10):
        self.max_turns = max_turns
        self.history: deque = deque(maxlen=max_turns)
    
    def add_exchange(self, speaker: str, text: str):
        """Add a dialogue exchange to history"""
        self.history.append({
            "speaker": speaker,
            "text": text,
            "timestamp": datetime.now().isoformat()
        })
    
    def get_context(self) -> List[Dict]:
        """Get recent conversation context"""
        return list(self.history)
    
    def clear(self):
        """Clear conversation history"""
        self.history.clear()
    
    def to_prompt(self) -> str:
        """Format history as prompt text"""
        lines = []
        for entry in self.history:
            lines.append(f"{entry['speaker']}: {entry['text']}")
        return "\n".join(lines)


class LongTermMemory:
    """Persistent character memory storage"""
    
    def __init__(self, character_id: str, storage_path: str = "memory"):
        self.character_id = character_id
        self.storage_path = storage_path
        self.memories: List[Dict] = []
        os.makedirs(storage_path, exist_ok=True)
        self._load()
    
    def _load(self):
        """Load memories from disk"""
        filepath = os.path.join(self.storage_path, f"{self.character_id}_memory.json")
        if os.path.exists(filepath):
            with open(filepath, 'r') as f:
                self.memories = json.load(f)
    
    def _save(self):
        """Save memories to disk"""
        filepath = os.path.join(self.storage_path, f"{self.character_id}_memory.json")
        with open(filepath, 'w') as f:
            json.dump(self.memories, f, indent=2)
    
    def add_memory(self, content: str, category: str, importance: float = 0.5, 
                   context_ref: Optional[str] = None):
        """Add a memory entry"""
        memory = {
            "id": f"mem_{datetime.now().timestamp()}",
            "content": content,
            "category": category,
            "importance": importance,
            "timestamp": datetime.now().isoformat(),
            "context_ref": context_ref
        }
        self.memories.append(memory)
        self._save()
    
    def get_relevant_memories(self, query: str, limit: int = 5) -> List[str]:
        """Get relevant memories (simple keyword matching for now)"""
        # Sort by importance, then recency
        sorted_memories = sorted(
            self.memories,
            key=lambda m: (m.get("importance", 0.5), m.get("timestamp", "")),
            reverse=True
        )
        return [m["content"] for m in sorted_memories[:limit]]
    
    def clear(self):
        """Clear all memories"""
        self.memories = []
        self._save()


class ContextManager:
    """Combined context management for dialogue generation"""
    
    def __init__(self, character_id: str, storage_path: str = "memory"):
        self.short_term = ShortTermMemory(max_turns=15)
        self.long_term = LongTermMemory(character_id, storage_path)
    
    def record_exchange(self, speaker: str, text: str):
        """Record a dialogue exchange"""
        self.short_term.add_exchange(speaker, text)
    
    def add_significant_memory(self, content: str, category: str, importance: float = 0.5):
        """Add important information to long-term memory"""
        self.long_term.add_memory(content, category, importance)
    
    def get_full_context(self) -> Dict[str, Any]:
        """Get complete context for prompt generation"""
        return {
            "short_term_history": self.short_term.get_context(),
            "relevant_memories": self.long_term.get_relevant_memories(""),
            "formatted_history": self.short_term.to_prompt()
        }
    
    def reset_conversation(self):
        """Clear short-term memory for new conversation"""
        self.short_term.clear()


if __name__ == "__main__":
    # Test the context manager
    ctx = ContextManager("test_character")
    ctx.record_exchange("Player", "Hello there!")
    ctx.record_exchange("NPC", "Greetings, traveler.")
    ctx.add_significant_memory("Player helped the merchant's son", "relationship", 0.8)
    
    print("Context:", json.dumps(ctx.get_full_context(), indent=2))