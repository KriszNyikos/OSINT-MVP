# Multi-stage Dockerfile for .NET 10 Web API
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy solution and project files for layer caching
COPY OsintPlatform.sln ./
COPY src/OsintPlatform.Core/*.csproj ./src/OsintPlatform.Core/
COPY src/OsintPlatform.Persistence/*.csproj ./src/OsintPlatform.Persistence/
COPY src/OsintPlatform.Collectors/*.csproj ./src/OsintPlatform.Collectors/
COPY src/OsintPlatform.Api/*.csproj ./src/OsintPlatform.Api/

RUN dotnet restore OsintPlatform.sln

# Copy source code and publish
COPY src/ ./src/
RUN dotnet publish src/OsintPlatform.Api/OsintPlatform.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "OsintPlatform.Api.dll"]
