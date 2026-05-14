"""
Persona Injection Framework for Consistent Character Behavior
"""

from typing import Dict, List, Optional
import json
import random


class CharacterPersona:
    """Defines character personality and speech patterns"""
    
    def __init__(self, persona_id: str, name: str, profile: Optional[Dict] = None):
        self.persona_id = persona_id
        self.name = name
        self.profile = profile or self._default_profile()
    
    def _default_profile(self) -> Dict:
        return {
            "core_traits": ["helpful", "curious"],
            "speech_patterns": {
                "formality": 0.5,
                "vocabulary_complexity": 0.5,
                "catchphrases": [],
                "greeting_styles": ["Hello", "Hi there"]
            },
            "emotional_baseline": "neutral",
            "knowledge_domains": []
        }
    
    @classmethod
    def from_file(cls, filepath: str) -> "CharacterPersona":
        """Load persona from JSON file"""
        with open(filepath, 'r') as f:
            data = json.load(f)
        persona = cls(data["persona_id"], data.get("name", "Unknown"))
        persona.profile = data.get("profile", persona._default_profile())
        return persona
    
    def get_system_prompt(self) -> str:
        """Generate system prompt for this persona"""
        traits = ", ".join(self.profile.get("core_traits", []))
        speech = self.profile.get("speech_patterns", {})
        
        prompt = f"""You are {self.name}.
Core personality traits: {traits}
Speech style: {self._describe_speech()}
Emotional baseline: {self.profile.get("emotional_baseline", "neutral")}

Guidelines for responses:
- Stay in character at all times
- Use consistent speech patterns
- Reference your knowledge domains when relevant
- Keep responses concise (2-4 sentences typically)
"""
        return prompt
    
    def _describe_speech(self) -> str:
        speech = self.profile.get("speech_patterns", {})
        formality = speech.get("formality", 0.5)
        complexity = speech.get("vocabulary_complexity", 0.5)
        catchphrases = speech.get("catchphrases", [])
        
        style_parts = []
        if formality > 0.7:
            style_parts.append("formal")
        elif formality < 0.3:
            style_parts.append("casual")
        else:
            style_parts.append("neutral")
        
        if complexity > 0.7:
            style_parts.append("complex vocabulary")
        
        if catchphrases:
            style_parts.append(f"occasional use of phrases like: {', '.join(catchphrases[:2])}")
        
        return ", ".join(style_parts) if style_parts else "standard speech"


class EmotionalState:
    """Manages character emotional state"""
    
    STATES = ["angry", "annoyed", "neutral", "friendly", "happy", "excited", "concerned"]
    
    def __init__(self, baseline: str = "neutral"):
        self.baseline = baseline
        self.current = baseline
        self.triggers = {}
    
    def apply_trigger(self, player_action: str, trigger_effects: Dict[str, str]):
        """Modify emotional state based on player actions"""
        if player_action in trigger_effects:
            self.current = trigger_effects[player_action]
    
    def reset(self):
        """Reset to baseline"""
        self.current = self.baseline
    
    def get_emotion_tags(self) -> List[str]:
        """Get tags describing current emotional state"""
        return [f"emotion:{self.current}"]


class PersonaInjector:
    """Injects persona into prompt generation"""
    
    def __init__(self, persona: CharacterPersona, emotional_state: Optional[Dict] = None):
        self.persona = persona
        self.emotional_state = EmotionalState(
            emotional_state.get("baseline", "neutral") if emotional_state else "neutral"
        )
        self.emotional_state.triggers = emotional_state.get("triggers", {}) if emotional_state else {}
    
    def inject_into_prompt(self, base_prompt: str, context: Dict) -> str:
        """Inject persona information into the prompt"""
        persona_prompt = self.persona.get_system_prompt()
        
        injected = f"""{persona_prompt}

Current emotional state: {self.emotional_state.current}

{'='*50}

{base_prompt}"""
        
        return injected


# Pre-defined personas for Fallout setting

FALLOUT_PERSONAS = {
    "vault_dweller": {
        "name": "Vault Dweller",
        "profile": {
            "core_traits": ["naive", "cautious", "curious"],
            "speech_patterns": {
                "formality": 0.6,
                "vocabulary_complexity": 0.4,
                "catchphrases": ["I don't understand...", "This is strange..."],
                "greeting_styles": ["Hello", "Um, greetings"]
            },
            "emotional_baseline": "cautious",
            "knowledge_domains": ["vault_life", "pre_war"]
        }
    },
    "brotherhood_knight": {
        "name": "Brotherhood Knight",
        "profile": {
            "core_traits": ["disciplined", "stoic", "duty-bound"],
            "speech_patterns": {
                "formality": 0.8,
                "vocabulary_complexity": 0.7,
                "catchphrases": ["For the Brotherhood!", "Technology must be preserved"],
                "greeting_styles": ["Greetings civilian", "At ease"]
            },
            "emotional_baseline": "neutral",
            "knowledge_domains": ["technology", "tactics", "brotherhood_history"]
        }
    },
    "raider_chief": {
        "name": "Raider Chief",
        "profile": {
            "core_traits": ["aggressive", "cunning", "dominant"],
            "speech_patterns": {
                "formality": 0.3,
                "vocabulary_complexity": 0.5,
                "catchphrases": ["You lookin' at me?", "Time to die!"],
                "greeting_styles": ["What do you want?", "Make it quick"]
            },
            "emotional_baseline": "hostile",
            "knowledge_domains": ["survival", "weaponry", "torture"]
        }
    },
    "ghoul_philosopher": {
        "name": "Ghoul Philosopher",
        "profile": {
            "core_traits": ["wise", "melancholic", "patient"],
            "speech_patterns": {
                "formality": 0.7,
                "vocabulary_complexity": 0.8,
                "catchphrases": ["In my 200 years...", "The wasteland teaches us..."],
                "greeting_styles": ["Well met, young one", "Peace be with you"]
            },
            "emotional_baseline": "thoughtful",
            "knowledge_domains": ["history", "philosophy", "wasteland_lore"]
        }
    }
}


def create_persona(persona_type: str) -> CharacterPersona:
    """Factory function to create predefined personas"""
    if persona_type in FALLOUT_PERSONAS:
        data = FALLOUT_PERSONAS[persona_type]
        return CharacterPersona(persona_type, data["name"], data["profile"])
    raise ValueError(f"Unknown persona type: {persona_type}")


if __name__ == "__main__":
    # Test persona creation
    knight = create_persona("brotherhood_knight")
    print(knight.get_system_prompt())