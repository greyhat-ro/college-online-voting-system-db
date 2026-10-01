# CampusVote Build & GitHub Portfolio Guide

## 1. Run the demo locally
Open the folder in VS Code and use Live Server. The demo uses synthetic data and localStorage.

## 2. Create Git repository
```bash
git init
git add .
git commit -m "Initial CampusVote project"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/college-online-voting-system.git
git push -u origin main
```

## 3. Enable GitHub Pages
GitHub repository → Settings → Pages → Build and deployment → Deploy from a branch → main → /(root) → Save.

Your public URL will be:
https://YOUR_USERNAME.github.io/college-online-voting-system/

## 4. Production backend
Use Supabase for Auth + PostgreSQL. Run `sql/schema.sql`, configure authentication, then replace demo localStorage with Supabase Auth and database calls.

## 5. Security
For a real election, use strict RLS, server/database-side authorization, duplicate-vote constraints, election-window enforcement, audit logging, secure secrets, and a ballot-secrecy design that separates voter identity from ballot choices as appropriate.

## 6. Portfolio additions
Add ERD, DFD Level 0/1/2, SRS, test cases, screenshots, architecture diagram, GitHub Issues/Projects, automated tests, and a deployment section.

## 7. Do not publish
Never put real student data, real ballots, credentials, internal college information or Supabase service-role keys in the public repository.
