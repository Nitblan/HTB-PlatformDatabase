# HTB Platform Database

Relational database project developed as part of the UNAM Cisco Networking Academy Database course.
A production-ready schema for a cybersecurity learning platform inspired by Hack The Box.

---

## Overview

HTB Platform Database models a complete ecosystem for users to track progress on cybersecurity machines, earn points, compete in rankings, and share feedback. The database follows Third Normal Form (3NF) normalization with strategic indexing and analytical views designed to scale from thousands to millions of users.

**Core Components:**
- 8 normalized relational tables implementing core entities and associations
- 2 analytical views calculating rankings and machine statistics in real-time
- Strategic indexing optimized for common access patterns
- Referential integrity constraints enforcing data consistency at database layer
- Composite keys and window functions demonstrating advanced SQL design

---

## Key Features

**Database Design**
- 3NF normalization eliminating data redundancy
- Composite primary keys in association tables (Progreso)
- Composite foreign keys enforcing business rules (Comentario)
- Strategic denormalization through counter columns for performance

**Data Integrity**
- Primary keys ensuring row uniqueness
- Foreign keys with ON DELETE CASCADE/RESTRICT based on semantics
- ENUM constraints restricting valid values (estado)
- NOT NULL and UNIQUE constraints on mandatory fields
- Referential integrity validated at database layer, not application

**Analytics and Reporting**
- v_ranking_usuario_global: User rankings with global and country-level partitioning
- v_ranking_maquina_dificultad: Machine statistics including completion rates and average solve times
- Window functions (ROW_NUMBER) for ranking calculation
- Conditional aggregation for multi-state tracking

**Scalability**
- Indexed joins for sub-millisecond authentication lookups
- Counter columns avoiding expensive COUNT(*) operations
- Design ready for partitioning at 10M+ rows
- Capacity estimated: 1M users with <500ms leaderboard queries

---

## Entity Relationship Diagram

The database consists of three layers:

**Lookup Tables** (Categoria, OS, Dificultad)
- Normalize categorical data
- Enable efficient filtering and classification
- Single source of truth for each category

**Core Entity Tables** (Usuario, Maquina)
- User profiles with authentication and activity tracking
- Machine inventory with multi-dimensional classification
- Audit trail through timestamps and activity counters

**Association and Audit Tables** (Progreso, Intento, Comentario)
- Progreso: N:M relationship between users and machines
- Intento: Detailed VPN connection audit log
- Comentario: User-generated content with structural constraints

**Relationship Diagrams:**

![ERD Part 1](assets/SQL1.png)
![ERD Part 2](assets/SQL2.png)

---

## Database Schema

### Tables (8 total)

**Categoria** - Machine categories (Linux, Web, Windows, Active Directory, OSINT)
- Normalized lookup table preventing duplication
- Indexed on name for quick filtering

**OS** - Operating systems (Linux, Windows, Web, Docker, Cloud)
- Lookup table with same pattern as Categoria
- Enables multi-dimensional machine classification

**Dificultad** - Difficulty levels with point ranges
- Fácil: 10-50 points
- Media: 50-100 points
- Difícil: 100-200 points
- Insane: 200-500 points

**Usuario** - Platform users
- Authentication: username (UNIQUE), email (UNIQUE)
- Password storage: hash only, never plaintext
- Soft delete support: activo boolean field
- Indexes: username (login), email (password recovery), country (rankings), active status

**Maquina** - Cybersecurity labs/machines
- Multi-dimensional classification: category, OS, difficulty
- Counter columns: intentos_totales, completadas
- Referential integrity: RESTRICT on lookup table deletions

**Progreso** - User-machine progress (N:M association)
- Composite PK: (id_usuario, id_maquina)
- Status tracking: en_progreso, completado, abandonado
- Metrics: points earned, time invested, attempt count

**Intento** - VPN connection audit log
- Granularity: one row per connection attempt
- Content: timestamps, success flag, error types, full logs, IP address
- Retention: suitable for archiving old records to separate table

**Comentario** - User comments on completed machines
- Composite FK to Progreso enforcing interaction requirement
- Automatic timestamp updates on modification
- Cascading deletion with user/machine removal

### Views (2 total)

**v_ranking_usuario_global**
- Global user ranking by total points
- Country-level ranking using PARTITION BY
- Aggregated statistics: completions, in-progress, abandoned counts
- Real-time calculation on each query

**v_ranking_maquina_dificultad**
- Machine statistics and difficulty validation
- Completion rate calculation with division-by-zero protection
- Average solve time for completed machines only
- Identifies mis-calibrated machines

---

## Installation

### Prerequisites
- MySQL 8.0+ or MariaDB 10.5+
- Command line access to MySQL
- Git for repository cloning

### Setup Steps

1. Clone repository
```bash
git clone https://github.com/Nitblan/HTB-PlatformDatabase.git
cd HTB-PlatformDatabase
```

2. Load database schema
```bash
mysql -u root -p < schema.sql
```

3. Verify installation
```bash
mysql -u root -p -e "USE htb_platform; SHOW TABLES;"
```

Expected output: 8 tables (Categoria, Comentario, Dificultad, Intento, Maquina, OS, Progreso, Usuario)

4. Test analytical views
```bash
mysql -u root -p htb_platform < tests/test-views.sql
```

---

## Usage Examples

### User Authentication
```sql
SELECT id_usuario, nombre_usuario, contraseña_hash
FROM Usuario
WHERE nombre_usuario = 'hacker_mx' AND activo = TRUE;
```

### Record Machine Completion
```sql
UPDATE Progreso
SET estado = 'completado', fecha_completado = NOW(), puntos_obtenidos = 50
WHERE id_usuario = 1 AND id_maquina = 5;
```

### Query Global Leaderboard
```sql
SELECT posicion_global, nombre_usuario, pais, puntos_totales
FROM v_ranking_usuario_global
ORDER BY posicion_global ASC
LIMIT 10;
```

### Analyze Machine Difficulty
```sql
SELECT nombre_maquina, dificultad, tasa_completacion_pct
FROM v_ranking_maquina_dificultad
WHERE tasa_completacion_pct < 30
ORDER BY tasa_completacion_pct ASC;
```

---

## Design Decisions

### Normalization Strategy (3NF)

**Separate Lookup Tables**
- "Linux" stored once, referenced 1000+ times
- Eliminates redundancy and typo risk
- Single indexed join (<1ms) vs storage waste

**Composite Primary Keys**
- Progreso(id_usuario, id_maquina): prevents duplicate states
- No surrogate key needed for association tables
- Natural join keys following FK structure

**Composite Foreign Keys**
- Comentario references (id_usuario, id_maquina) in Progreso
- Structural enforcement: comments require interaction record
- Prevents orphaned comments at database layer

### Referential Integrity

**ON DELETE RESTRICT** (Lookup tables)
- Protects Categoria, OS, Dificultad from accidental deletion
- Forces explicit handling if deleting shared resources
- Safety mechanism for data consistency

**ON DELETE CASCADE** (User-owned data)
- Progreso, Intento, Comentario cascade with user deletion
- Semantic alignment: data "owned" by user
- Prevents orphaned records cluttering database

### Strategic Denormalization

**Counter Columns**
- num_intentos_totales, num_completadas
- Avoids expensive COUNT(*) on millions of rows
- Write cost: minor (increment on Progreso change)
- Read benefit: massive (instant access to totals)

### Index Strategy

User indexes: username (login), email (password recovery), country (rankings), active status
Machine indexes: category, OS, difficulty (filtering), name (lookup), active (display)
Progress indexes: user (history), state (analytics)
Attempt indexes: user (audit trail), date (time-range), success (analysis)

---

## Performance Characteristics

**Estimated Query Performance**
- User login: O(log n), <1ms for 1M users
- Global leaderboard (top 10): <500ms for 1M users, 10M Progreso rows
- Machine stats: <200ms for 100K machines
- User history: <100ms for 10M Intento rows

**Scalability Roadmap**
- 100K users: current schema sufficient
- 1M users: add composite index (pais, puntos_totales)
- 10M+ users: partition Progreso/Intento by date ranges

---

## Project Structure

```
HTB-PlatformDatabase/
├── README.md                 Main documentation
├── ARCHITECTURE.md           Design decisions and rationales
├── SETUP.md                  Installation guide
├── REPORT.md                 Academic project report
├── LICENSE                   MIT License
├── .gitignore
│
├── schema.sql                Complete DDL (tables, views, indexes)
├── QUERIES_EXAMPLES.sql      Common query patterns
├── APUNTES_OBSIDIAN.md       Spanish notes from Obsidian
│
├── tests/
│   ├── test-views.sql
│   ├── test-integrity.sql
│   └── test-performance.sql
│
└── assets/
    ├── SQL1.png              ERD diagram part 1
    └── SQL2.png              ERD diagram part 2
```

---

## Technologies

- SQL: DDL, DML, Views, Window Functions
- MySQL 8.0+ and MariaDB 10.5+
- Relational database modeling
- Query optimization

---

## Learning Outcomes

This project demonstrates:

**Database Architecture**
- 3NF normalization reducing redundancy to theoretical limits
- Strategic denormalization for measurable performance gains
- Composite keys and their appropriate applications

**Advanced SQL**
- Window functions (ROW_NUMBER, PARTITION BY) for ranking
- Conditional aggregation (COUNT CASE WHEN)
- Defensive NULL handling (COALESCE, NULLIF)
- View-based analytics without data duplication

**Data Integrity**
- Foreign key constraints with semantic actions
- Composite key enforcement at database layer
- Business rule validation through structural constraints

**Scalability**
- Strategic indexing based on access pattern analysis
- Preparation for millions of rows through design
- Partitioning strategies for future scaling

---

## Documentation

Detailed documentation available:

- **ARCHITECTURE.md**: Design decisions, trade-offs, and rationales
- **SETUP.md**: Step-by-step installation and verification
- **REPORT.md**: Academic project report with conceptual, logical, and physical models
- **QUERIES_EXAMPLES.sql**: Real-world query patterns organized by use case
- **APUNTES_OBSIDIAN.md**: Complete Spanish notes documenting all design details

---

## Course Information

- Institution: UNAM (Universidad Nacional Autónoma de México)
- Program: Cisco Networking Academy
- Course: Introduction to Databases
- Project Type: Relational Database Design and Implementation
- Date: January 2025

---


## Acknowledgments

UNAM Cisco Networking Academy for course structure and guidance.
Database design principles from standard relational theory.
MySQL documentation for implementation details.
