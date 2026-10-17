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
        // Keycloak realm URL – the middleware fetches JWKS and issuer metadata from here automatically.
        options.Authority = keycloakConfig["Authority"];

        // Must match the "aud" claim in tokens issued for osint-backend client.
        options.Audience = keycloakConfig["Audience"];

        // Allow plain HTTP in development; must be true in production.
        options.RequireHttpsMetadata =
            bool.Parse(keycloakConfig["RequireHttpsMetadata"] ?? "true");

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,           // iss must match Authority
            ValidateAudience = true,         // aud must match Audience
            ValidateLifetime = true,         // exp must be in the future
            ValidateIssuerSigningKey = true, // RS256 signature verified against JWKS
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
