# Supabase Deployment on Runflare

This repository contains the necessary configuration to deploy Supabase Studio on the Runflare cloud platform.

## Project Structure

- `Dockerfile`: Defines the base image for Supabase Studio (`supabase/studio:latest`) and exposes port 3000.
- `README.md`: Project documentation and deployment instructions.

## Prerequisites

- [Runflare CLI](https://runflare.com/) installed on your local machine.
- An active Runflare account with an authenticated CLI session (`runflare login`).

## Deployment Instructions

1. Open your terminal (PowerShell) in the project directory.
2. If you are logging in for the first time or need to refresh your session, run:
   ```powershell
   runflare login
   ```
3. Run the deployment command specifying your project name and item name:
   ```powershell
   runflare deploy --project-name supabasesecond --item-name supabase-app
   ```

## Ports and Configuration

- **Exposed Port:** 3000 (Supabase Studio Dashboard)
- **Base Image:** `supabase/studio:latest`
