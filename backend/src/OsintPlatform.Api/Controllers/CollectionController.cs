using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace OsintPlatform.Api.Controllers;

/// <summary>
/// Manages data collection jobs.
/// - GET  /api/collection/status  → requires "viewer" or "admin" role (any authenticated user)
/// - POST /api/collection/start   → requires "admin" role only; returns 403 for "viewer"
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CollectionController : ControllerBase
{
    /// <summary>
    /// Returns the current collection status. Accessible to all authenticated users.
    /// </summary>
    [HttpGet("status")]
    [Authorize(Policy = "ViewerOrAbove")]
    public IActionResult GetStatus()
    {
        return Ok(new { status = "idle", timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Starts a new data collection job. Restricted to the "admin" role.
    /// Callers with only the "viewer" role receive 403 Forbidden.
    /// </summary>
    [HttpPost("start")]
    [Authorize(Policy = "AdminOnly")]
    public IActionResult StartCollection()
    {
        return Accepted(new { message = "Collection job queued", timestamp = DateTime.UtcNow });
    }
}
