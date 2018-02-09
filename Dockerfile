FROM microsoft/aspnetcore-build:2.0.0 as builder
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY ./WebAppCore2/*.csproj .
RUN dotnet restore

# Copy everything else and build
COPY ./WebAppCore2/ .
RUN dotnet publish -c Release -o out

# Build runtime image
FROM microsoft/aspnetcore:2.0
WORKDIR /app
COPY --from=builder /app/out .

ENTRYPOINT ["dotnet", "WebAppCore2.dll"]