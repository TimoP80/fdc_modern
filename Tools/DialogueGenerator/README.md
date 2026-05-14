# Procedural Dialogue Generator

Offline dialogue generation system using Ollama for Fallout-like games.

## Prerequisites

1. Install Ollama: https://ollama.com/download
2. Pull a model: `ollama pull llama3.1`

## Quick Start

```bash
cd Tools\DialogueGenerator
python dialogue_generator.py
```

## Usage

```python
from dialogue_generator import DialogueGenerator
from persona import create_persona

# Create generator with predefined persona
generator = DialogueGenerator(
    character_id="merchant_elias",
    model="llama3.1",
    persona=create_persona("ghoul_philosopher")
)

# Generate dialogue
response = generator.generate_dialogue(
    player_input="What do you know about the old world?",
    game_state={"location": "ruins", "time": "evening"}
)

print(f"NPC: {response['text']}")

# Reset conversation
generator.reset_conversation()
```

## Available Personas

- `vault_dweller` - Naive, cautious survivor
- `brotherhood_knight` - Disciplined tech-keeper  
- `raider_chief` - Aggressive wasteland tyrant
- `ghoul_philosopher` - Wise but decaying observer

## Command Line Options

When running interactively:
- Type normally to converse
- `reset` - Start fresh conversation
- `quit` - Exit

## Memory Files

Memory is stored in the `memory/` directory as JSON files organized by character ID.