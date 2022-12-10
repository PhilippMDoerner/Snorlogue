# Project Setup

Overview over the project structure:
- snorlogue:
  - backend - For controller procs of POST requests (and related code) to create/update/delete database entries
  - frontend - For controller procs of GET requests (and related code) to read database entries
  - repository - Implementations of CRUD operations for all supported databases. Do not use directly, import `genericRepository`
  - resources - Nimja Template-, CSS-, JS- and other files needed to generate HTML
