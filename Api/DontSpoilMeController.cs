using Jellyfin.Plugin.DontSpoilMe.Configuration;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Jellyfin.Plugin.DontSpoilMe.Api;

[ApiController]
[Route("DontSpoilMe")]
[Authorize(Policy = "RequiresElevation")]
public class DontSpoilMeController : ControllerBase
{
    [HttpGet("Config")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<PluginConfiguration> GetConfig()
        => Plugin.Instance?.Configuration ?? new PluginConfiguration();

    [HttpPost("Config")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public ActionResult SetConfig([FromBody] PluginConfiguration config)
    {
        if (Plugin.Instance is null)
            return StatusCode(StatusCodes.Status503ServiceUnavailable);
        Plugin.Instance.UpdateConfiguration(config);
        return NoContent();
    }
}
