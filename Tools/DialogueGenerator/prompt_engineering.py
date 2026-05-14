"""
Dynamic Prompt Engineering for Dialogue Generation
Transforms game state into natural language instructions
"""

from typing import Dict, List, Optional, Any
import json


class GameStateTransformer:
    """Transforms raw game state into prompt-friendly format"""
    
    def __init__(self):
        self.category_mappings = {
            "reputation": self._format_reputation,
            "inventory": self._format_inventory,
            "location": self._format_location,
            "quests": self._format_quests,
            "time": self._format_time,
            "health": self._format_health,
            "skills": self._format_skills
        }
    
    def transform(self, game_state: Dict[str, Any], 
                response_type: str = "dialogue") -> Dict[str, Any]:
        """Transform game state into prompt-friendly format"""
        result = {
            "context_blocks": [],
            "player_analysis": {},
            "world_analysis": {}
        }
        
        for key, value in game_state.items():
            if key in self.category_mappings:
                formatted = self.category_mappings[key](value)
                if formatted:
                    result["context_blocks"].append(formatted)
                    result[self._get_category(key)].update({
                        key: self._analyze_value(key, value)
                    })
        
        return result
    
    def _format_reputation(self, value: Dict) -> str:
        if not value:
            return ""
        highest = max(value.items(), key=lambda x: x[1])
        lowest = min(value.items(), key=lambda x: x[1])
        
        parts = []
        if highest[1] > 50:
            parts.append(f"Well-regarded by {highest[0]} ({highest[1]})")
        if lowest[1] < -30:
            parts.append(f"Hated by {lowest[0]} ({lowest[1]})")
        
        return "; ".join(parts) if parts else "Neutral reputation"
    
    def _format_inventory(self, value: List[Dict]) -> str:
        if not value:
            return "Carrying few possessions"
        
        notable = [item for item in value 
                   if item.get("rarity", "common") in ["rare", "unique"]]
        if notable:
            names = [item["name"] for item in notable[:3]]
            return f"Notable items: {', '.join(names)}"
        return f"Carrying {len(value)} items"
    
    def _format_location(self, value: str) -> str:
        return f"Current location: {value}"
    
    def _format_quests(self, value: List[Dict]) -> str:
        active = [q for q in value if q.get("status") == "active"]
        if not active:
            return ""
        
        names = [q["name"] for q in active[:2]]
        return f"Active quests: {', '.join(names)}"
    
    def _format_time(self, value: str) -> str:
        time_descriptions = {
            "dawn": "early morning",
            "day": "midday",
            "dusk": "evening",
            "night": "late at night"
        }
        return f"Time: {time_descriptions.get(value, value)}"
    
    def _format_health(self, value: Dict) -> str:
        hp = value.get("current", 0)
        max_hp = value.get("max", 100)
        ratio = hp / max_hp
        
        if ratio < 0.25:
            return "NPC notices you appear badly wounded"
        elif ratio < 0.5:
            return "NPC notices you're hurt"
        return ""
    
    def _format_skills(self, value: Dict) -> str:
        high = {k: v for k, v in value.items() if v > 75}
        if not high:
            return ""
        skills = list(high.keys())[:2]
        return f"Impressive skills noted: {', '.join(skills)}"
    
    def _get_category(self, key: str) -> str:
        player_keys = ["reputation", "inventory", "health", "skills"]
        world_keys = ["location", "quests", "time"]
        
        if key in player_keys:
            return "player_analysis"
        return "world_analysis"
    
    def _analyze_value(self, key: str, value: Any) -> Dict:
        """Simple analysis of game state values"""
        return {"raw": value, "present": True}


class PromptBuilder:
    """Builds optimized prompts for LLM generation"""
    
    def __init__(self):
        self.transformer = GameStateTransformer()
    
    def build(self, base_prompt: str, game_state: Dict,
            context: Dict = None, persona_prompt: str = "") -> str:
        """Build complete prompt with all components"""
        
        transformed = self.transformer.transform(game_state)
        
        prompt_parts = []
        
        # Add persona system prompt first
        if persona_prompt:
            prompt_parts.append(persona_prompt)
        
        # Add structured context
        if transformed["context_blocks"]:
            prompt_parts.append("\nRelevant Context:")
            prompt_parts.extend(transformed["context_blocks"])
        
        # Add conversation history if present
        if context and context.get("formatted_history"):
            prompt_parts.append(f"\n{context['formatted_history']}")
        
        # Add current situation
        prompt_parts.append(f"\n{base_prompt}")
        
        # Add style instructions
        prompt_parts.append("""
Response Guidelines:
- Stay in character
- Be concise (2-4 sentences)
- Reference relevant context naturally
- If offering new quest/info, prefix with [QUEST] or [INFO]""")
        
        return "\n".join(prompt_parts)


if __name__ == "__main__":
    # Test prompt builder
    pb = PromptBuilder()
    
    test_state = {
        "reputation": {"brotherhood": 75, "raiders": -20},
        "inventory": [{"name": "Laser Pistol", "rarity": "rare"}],
        "location": "Megaton",
        "quests": [{"name": "Water Purification", "status": "active"}],
        "time": "dusk",
        "health": {"current": 45, "max": 100}
    }
    
    prompt = pb.build(
        "Player asks about trading",
        test_state
    )
    
    print(prompt)