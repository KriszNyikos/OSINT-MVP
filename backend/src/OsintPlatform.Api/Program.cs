using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authentication;
using Microsoft.IdentityModel.Tokens;
using OsintPlatform.Api.Infrastructure.Auth;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddHealthChecks();

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// CORS configuration for Angular frontend
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:4200")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// ---------------------------------------------------------------------------
// Authentication – Keycloak OIDC / JWT Bearer
// Configuration is read from appsettings.json (or overridden by env vars in Docker).
// No secrets are stored here: token validation uses Keycloak's public JWKS endpoint.
// ---------------------------------------------------------------------------
var keycloakConfig = builder.Configuration.GetSection("Authentication:Keycloak");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Authority is used to fetch JWKS from Keycloak.
        // In Docker this points to the internal service name (keycloak:8080) so the backend
        // can reach Keycloak on the internal Docker network.
        options.Authority = keycloakConfig["Authority"];

        // Must match the "aud" claim in tokens issued for osint-backend client.
        options.Audience = keycloakConfig["Audience"];

        // Allow plain HTTP in development; must be true in production.
        options.RequireHttpsMetadata =
            bool.Parse(keycloakConfig["RequireHttpsMetadata"] ?? "true");

        // In Docker, tokens are issued with the public hostname in the "iss" claim (e.g. localhost:8080)
        // while Authority points to the internal hostname (e.g. keycloak:8080).
        // ValidIssuers accepts both internal and external hostnames so tokens are valid regardless of origin.
        var authority = keycloakConfig["Authority"] ?? string.Empty;
        var validIssuer = keycloakConfig["ValidIssuer"];

        var validIssuers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (!string.IsNullOrEmpty(authority)) validIssuers.Add(authority);
        if (!string.IsNullOrEmpty(validIssuer)) validIssuers.Add(validIssuer);

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuers = validIssuers,
            ValidateAudience = true,
            ValidAudience = keycloakConfig["Audience"],
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
        };
    });

// ---------------------------------------------------------------------------
// Authorization – role-based policies
// Role names match the Keycloak realm definition in docker/keycloak/osint-realm.json.
// ---------------------------------------------------------------------------
builder.Services.AddAuthorization(options =>
{
    // Only "admin" role can trigger data collection.
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("admin"));

    // Both "admin" and "viewer" can access read-only endpoints.
    options.AddPolicy("ViewerOrAbove", policy => policy.RequireRole("admin", "viewer"));
});

// Unpacks Keycloak's "realm_access.roles" JWT claim into standard ClaimTypes.Role entries.
builder.Services.AddScoped<IClaimsTransformation, KeycloakRolesClaimsTransformation>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowFrontend");

// UseAuthentication MUST come before UseAuthorization.
app.UseAuthentication();
app.UseAuthorization();

app.MapHealthChecks("/health");
app.MapControllers();

app.Run();
