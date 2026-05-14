"""
Procedural Dialogue Generator - Main Module
Offline dialogue generation using Ollama
"""

import subprocess
import json
from typing import Dict, List, Optional, Any
from context_manager import ContextManager
from persona import CharacterPersona, PersonaInjector, create_persona


class OllamaClient:
    """Simple client for Ollama API via command line"""
    
    def __init__(self, model: str = "llama3.1", host: str = "http://localhost:11434"):
        self.model = model
        self.host = host
    
    def generate(self, prompt: str, temperature: float = 0.7, max_tokens: int = 200) -> str:
        """Generate text using Ollama CLI"""
        cmd = [
            "ollama", "run", self.model,
            "--temperature", str(temperature),
            "--max-tokens", str(max_tokens)
        ]
        
        result = subprocess.run(
            cmd,
            input=prompt,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        return result.stdout.strip()
    
    def generate_structured(self, prompt: str, schema: Dict = None) -> Dict:
        """Generate and return as JSON if possible"""
        response = self.generate(prompt, max_tokens=300)
        
        # Try to extract JSON from response
        try:
            # Find JSON in response
            start = response.find("{")
            end = response.rfind("}") + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except (json.JSONDecodeError, ValueError):
            pass
        
        return {"text": response}


class DialogueGenerator:
    """Main dialogue generation system"""
    
    def __init__(self, character_id: str, model: str = "llama3.1", 
                 persona: Optional[CharacterPersona] = None,
                 storage_path: str = "memory"):
        self.context = ContextManager(character_id, storage_path)
        self.ollama = OllamaClient(model=model)
        
        if persona:
            self.persona = persona
        else:
            # Default to vault dweller
            self.persona = create_persona("vault_dweller")
        
        self.injector = PersonaInjector(self.persona)
    
    def generate_dialogue(self, player_input: str, 
                        game_state: Optional[Dict] = None) -> Dict[str, Any]:
        """Generate NPC response to player input"""
        
        # Record exchange
        self.context.record_exchange("Player", player_input)
        
        # Build prompt
        prompt = self._build_prompt(player_input, game_state)
        
        # Generate response
        raw_response = self.ollama.generate(prompt)
        
        # Parse response (simple for now)
        response = self._parse_response(raw_response)
        
        # Record NPC response
        self.context.record_exchange(self.persona.name, response.get("text", ""))
        
        # Extract and store significant memories
        self._extract_memories(player_input, response)
        
        return response
    
    def _build_prompt(self, player_input: str, game_state: Optional[Dict]) -> str:
        """Build complete prompt for generation"""
        ctx = self.context.get_full_context()
        
        # Base prompt
        base = f"""Recent conversation:
{ctx["formatted_history"]}

Player says: {player_input}

Respond as {self.persona.name}. Keep response under 3 sentences.
"""
        
        # Add game state context if provided
        if game_state:
            state_parts = []
            for key, value in game_state.items():
                state_parts.append(f"{key}: {value}")
            base += f"\nContext: {', '.join(state_parts)}"
        
        # Inject persona
        return self.injector.inject_into_prompt(base, ctx)
    
    def _parse_response(self, response: str) -> Dict:
        """Parse LLM response into structured format"""
        return {
            "text": response,
            "speaker": self.persona.name,
            "emotion": self.injector.emotional_state.current
        }
    
    def _extract_memories(self, player_input: str, response: Dict):
        """Extract significant information for long-term memory"""
        # Simple keyword-based extraction
        significant_keywords = ["name", "quest", "item", "important", "remember", "help"]
        
        combined = (player_input + " " + response.get("text", "")).lower()
        
        for keyword in significant_keywords:
            if keyword in combined:
                # Store as memory (simplified)
                if len(player_input) > 20:  # Only if substantial
                    self.context.add_significant_memory(
                        f"Conversation about {keyword}: {player_input[:100]}",
                        "dialogue",
                        importance=0.6
                    )
                break
    
    def reset_conversation(self):
        """Start fresh conversation with character"""
        self.context.reset_conversation()
        self.injector.emotional_state.reset()


def main():
    """Interactive dialogue demo"""
    import sys
    
    print("=== Procedural Dialogue Generator ===")
    print("Using Ollama for offline dialogue generation\n")
    
    # Create generator
    generator = DialogueGenerator("test_npc", model="llama3.1")
    
    print(f"NPC: {generator.persona.name}")
    print("(Type 'quit' to exit, 'reset' for new conversation)\n")
    
    while True:
        try:
            player_input = input("You: ").strip()
            
            if player_input.lower() == 'quit':
                break
            elif player_input.lower() == 'reset':
                generator.reset_conversation()
                print("\n[New conversation started]\n")
                continue
            
            if not player_input:
                continue
            
            # Generate response
            response = generator.generate_dialogue(player_input)
            print(f"\n{generator.persona.name}: {response['text']}\n")
            
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"\nError: {e}\n")
    
    print("\nGoodbye!")


if __name__ == "__main__":
    main()