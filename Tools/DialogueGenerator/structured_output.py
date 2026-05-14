"""
Structured JSON Output Schema for Dialogue Responses
Ensures easy integration with game engines
"""

from typing import Dict, List, Optional, Any
from enum import Enum
import json


class ActionType(Enum):
    QUEST_START = "quest_start"
    QUEST_COMPLETE = "quest_complete"
    QUEST_UPDATE = "quest_update"
    ITEM_GRANT = "item_grant"
    STAT_CHANGE = "stat_change"
    SHOP_OPEN = "shop_open"
    TELEPORT = "teleport"
    NONE = "none"


class DialogueResponse:
    """Structured dialogue response format"""
    
    def __init__(self):
        self.text: str = ""
        self.speaker: str = ""
        self.audio_cues: Dict[str, Any] = {}
        self.game_actions: List[Dict] = []
        self.choices: List[Dict] = []
        self.npc_changes: Dict[str, Any] = {}
        self.metadata: Dict[str, Any] = {}
    
    def to_dict(self) -> Dict[str, Any]:
        result = {
            "dialogue_response": {
                "text": self.text,
                "speaker": self.speaker,
                "audio_cues": self.audio_cues,
                "game_actions": self.game_actions,
                "choices": self.choices,
                "npc_changes": self.npc_changes
            }
        }
        
        if self.metadata:
            result["dialogue_response"]["metadata"] = self.metadata
        
        return result
    
    def to_json(self) -> str:
        return json.dumps(self.to_dict(), indent=2)
    
    @classmethod
    def from_dict(cls, data: Dict) -> "DialogueResponse":
        dr = cls()
        resp_data = data.get("dialogue_response", data)
        
        dr.text = resp_data.get("text", "")
        dr.speaker = resp_data.get("speaker", "")
        dr.audio_cues = resp_data.get("audio_cues", {})
        dr.game_actions = resp_data.get("game_actions", [])
        dr.choices = resp_data.get("choices", [])
        dr.npc_changes = resp_data.get("npc_changes", {})
        dr.metadata = resp_data.get("metadata", {})
        
        return dr


class AudioCueBuilder:
    """Builds audio cue information for dialogue"""
    
    @staticmethod
    def infer_from_text(text: str, emotion: str = "neutral") -> Dict[str, Any]:
        """Infer audio cues from text content"""
        cues = {"tone": emotion}
        
        # Detect emphasis/indication
        emphasis = []
        words = text.split()
        for i, word in enumerate(words):
            if word.isupper() and len(word) > 2:
                emphasis.append(i)
        
        if emphasis:
            cues["emphasis"] = emphasis
        
        return cues


class GameActionBuilder:
    """Builds structured game actions"""
    
    @staticmethod
    def create_quest_action(quest_id: str, action_type: ActionType,
                           payload: Dict = None) -> Dict:
        return {
            "type": action_type.value,
            "quest_id": quest_id,
            "payload": payload or {}
        }
    
    @staticmethod
    def create_item_action(item_id: str, action: str = "grant") -> Dict:
        return {
            "type": action,
            "item_id": item_id
        }
    
    @staticmethod
    def create_stat_action(stat: str, value: int) -> Dict:
        return {
            "type": "stat_change",
            "stat": stat,
            "value": value
        }


class ChoiceBuilder:
    """Builds player choice options"""
    
    @staticmethod
    def create_choice(text: str, next_tag: str = None,
                    requirements: Dict = None) -> Dict:
        return {
            "text": text,
            "next_tag": next_tag,
            "requirements": requirements or {}
        }


# Output format specification for LLM parsing
OUTPUT_SCHEMA = """
Format your response as valid JSON:
{
  "dialogue_response": {
    "text": "Your dialogue response here",
    "speaker": "Character name",
    "audio_cues": {"tone": "emotional_state"},
    "game_actions": [
      {"type": "quest_start|quest_complete|item_grant|stat_change|shop_open|none", "payload": {}}
    ],
    "choices": [
      {"text": "Player choice text", "next_tag": "dialogue_node_tag"}
    ]
  }
}

Required fields: text, speaker
Optional: audio_cues, game_actions, choices
Only include game_actions if player receives items, quests, or stat changes.
"""


def parse_structured_response(llm_response: str, character_name: str,
                              emotion: str = "neutral") -> DialogueResponse:
    """Parse LLM response into structured format"""
    dr = DialogueResponse()
    
    # Try to extract JSON from response
    try:
        # Find JSON object in response
        start = llm_response.find("{")
        end = llm_response.rfind("}") + 1
        
        if start >= 0 and end > start:
            json_str = llm_response[start:end]
            parsed = json.loads(json_str)
            dr = DialogueResponse.from_dict(parsed)
        else:
            dr.text = llm_response
    except (json.JSONDecodeError, ValueError):
        # Fallback to raw text
        dr.text = llm_response
    
    dr.speaker = character_name
    dr.audio_cues = AudioCueBuilder.infer_from_text(dr.text, emotion)
    
    return dr


if __name__ == "__main__":
    # Test structured output
    response = DialogueResponse()
    response.text = "Ah, you seek the ancient artifact. Many have tried..."
    response.speaker = "Elias Thorn"
    response.game_actions = [
        GameActionBuilder.create_quest_action("artifact_hunt", ActionType.QUEST_START, {
            "title": "The Cursed Artifact"
        })
    ]
    response.choices = [
        ChoiceBuilder.create_choice("Tell me more", "artifact_details"),
        ChoiceBuilder.create_choice("I'm not interested", None)
    ]
    
    print(response.to_json())