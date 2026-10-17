using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication;

namespace OsintPlatform.Api.Infrastructure.Auth;

/// <summary>
/// Transforms Keycloak JWT claims so that realm roles become standard .NET ClaimTypes.Role claims.
/// Keycloak nests roles inside "realm_access": { "roles": [...] } instead of using the standard
/// claim type, so this transformation is required for [Authorize(Roles=...)] and policy checks to work.
/// </summary>
public class KeycloakRolesClaimsTransformation : IClaimsTransformation
{
    public Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        var realmAccess = principal.FindFirst("realm_access");
        if (realmAccess is null)
            return Task.FromResult(principal);

        using var doc = JsonDocument.Parse(realmAccess.Value);
        if (!doc.RootElement.TryGetProperty("roles", out var roles))
            return Task.FromResult(principal);

        var identity = (ClaimsIdentity)principal.Identity!;
        foreach (var role in roles.EnumerateArray())
        {
            var roleName = role.GetString();
            if (!string.IsNullOrEmpty(roleName))
                identity.AddClaim(new Claim(ClaimTypes.Role, roleName));
        }

        return Task.FromResult(principal);
    }
}
