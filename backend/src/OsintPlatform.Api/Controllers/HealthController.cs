using Microsoft.AspNetCore.Mvc;

namespace OsintPlatform.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "Healthy",
            service = "OSINT Platform .NET Web API",
            timestamp = DateTime.UtcNow,
            version = "1.0.0-alpha"
        });
    }
}
