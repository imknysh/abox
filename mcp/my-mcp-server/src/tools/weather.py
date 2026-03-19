from core.server import mcp
from core.utils import get_tool_config, get_env_var

@mcp.tool()
def weather(location: str) -> str:
    """Get weather information for a location."""
    
    # Get tool configuration
    config = get_tool_config("weather")
    api_key = get_env_var(config.get("api_key_env", "WEATHER_API_KEY"))
    base_url = config.get("base_url", "https://api.openweathermap.org/data/2.5")
    
    # TODO: Implement weather API call
    return f"Weather for {location}: Sunny, 72°F"