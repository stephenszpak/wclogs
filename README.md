# WC Logs - World of Warcraft Combat Log Analyzer

A web application that mimics Warcraft Logs functionality for World of Warcraft combat logs, built with Elixir/Phoenix backend and React frontend. Supports parsing Mists of Pandaria Classic combat logs.

## Features

- **File Upload**: Drag-and-drop or select WoW combat log files (.txt, .log)
- **Combat Log Parsing**: Parses MoP Classic combat log format
- **Encounter Analysis**: Automatically detects boss encounters with start/end times
- **Damage Meters**: View damage done, DPS, healing done, HPS by player
- **Interactive UI**: Browse reports, encounters, and detailed participant statistics
- **Dockerized**: Full containerization with Docker Compose

## Tech Stack

**Backend:**
- Elixir 1.14+
- Phoenix Framework 1.7+
- PostgreSQL
- Ecto (Database ORM)

**Frontend:**
- React 18
- React Router
- Axios for API calls
- Modern CSS with responsive design

**Infrastructure:**
- Docker & Docker Compose
- Multi-stage builds for optimization

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Running with Docker (Recommended)

1. Clone the repository:
```bash
git clone <repository-url>
cd wclogs
```

2. Build and start the application:
```bash
docker-compose up --build
```

3. The application will be available at:
   - **Frontend**: http://localhost:4001 (served by Phoenix)
   - **API**: http://localhost:4001/api

4. Upload a combat log file and start analyzing!

### Development Setup

#### Backend (Phoenix)

1. Install dependencies:
```bash
cd wclogs
mix deps.get
```

2. Setup database:
```bash
mix ecto.setup
```

3. Start Phoenix server:
```bash
mix phx.server
```

#### Frontend (React)

1. Install dependencies:
```bash
cd frontend
npm install
```

2. Start development server:
```bash
npm start
```

The React dev server runs on http://localhost:3000 and proxies API calls to Phoenix on http://localhost:4001.

## Usage

### Uploading Combat Logs

1. Navigate to the home page
2. Drag and drop a `.txt` or `.log` combat log file, or click to select
3. Click "Upload and Parse" to process the file
4. Wait for parsing to complete (may take a few seconds for large files)

### Viewing Reports

1. After upload, you'll see the report listed on the home page
2. Click on a report to view all encounters found in that log
3. Click on an encounter to see detailed participant statistics

### Encounter Details

The encounter view provides three tabs:
- **Damage Done**: Players sorted by total damage and DPS
- **Healing Done**: Players sorted by total healing and HPS
- **Overview**: All participants with damage, healing, and death statistics

## Combat Log Format Support

Currently supports Mists of Pandaria Classic combat log format:

- `ENCOUNTER_START` / `ENCOUNTER_END` events for boss fights
- `SPELL_DAMAGE`, `SPELL_PERIODIC_DAMAGE`, `SWING_DAMAGE` for damage events
- `SPELL_HEAL`, `SPELL_PERIODIC_HEAL` for healing events
- `UNIT_DIED` for death tracking
- `COMBATANT_INFO` for player information (item level, etc.)

## API Endpoints

### Reports
- `GET /api/reports` - List all reports
- `POST /api/reports` - Upload new combat log (multipart/form-data)
- `GET /api/reports/:id` - Get specific report with encounters

### Encounters
- `GET /api/reports/:id/encounters/:encounter_id` - Get encounter details with participants

## Database Schema

### Reports
- Filename, upload metadata, time range, zone information

### Encounters
- Boss name, success/wipe status, duration, timestamps
- Links to parent report

### Participants
- Player name, GUID, class, spec
- Damage/healing totals, DPS/HPS calculations
- Death count, item level
- Links to parent encounter

## Configuration

### Environment Variables

**Production (Docker):**
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Hostname for Phoenix
- `PHX_SERVER` - Set to "true" to start server

**Development:**
- Database settings in `config/dev.exs`
- Phoenix server settings in `config/dev.exs`

## Development

### Adding New Combat Events

1. Extend the parser in `lib/wc_logs/parser.ex`
2. Add new event type parsing in `parse_event/2`
3. Update participant statistics processing
4. Add database migrations if new fields needed

### Frontend Components

- `Home.js` - File upload and reports list
- `ReportView.js` - Report details and encounters list
- `EncounterView.js` - Encounter details with participant tables
- `FileUpload.js` - Drag-and-drop file upload component

### Database Migrations

Create new migrations:
```bash
mix ecto.gen.migration migration_name
```

Run migrations:
```bash
mix ecto.migrate
```

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Ensure PostgreSQL is running
   - Check connection parameters in config files
   - For Docker: ensure database service is healthy

2. **File Upload Fails**
   - Check file format (.txt or .log only)
   - Ensure file is a valid WoW combat log
   - Check backend logs for parsing errors

3. **Parsing Issues**
   - Some log formats may not be fully supported
   - Check `lib/wc_logs/parser.ex` for format compatibility
   - Large files may take time to process

### Logs

**Docker:**
```bash
docker-compose logs web
docker-compose logs db
```

**Development:**
- Phoenix logs appear in terminal
- React logs in browser console

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

[Add your license here]

## Acknowledgments

- Inspired by [Warcraft Logs](https://www.warcraftlogs.com/)
- Built for World of Warcraft Mists of Pandaria Classic
- Thanks to the Elixir and React communities