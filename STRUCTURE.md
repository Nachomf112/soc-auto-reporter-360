soc-auto-reporter-360/
├─ backend/
│  ├─ app/
│  │  ├─ api/
│  │  │  ├─ v1/
│  │  │  │  ├─ endpoints/
│  │  │  │  │  ├─ nmap.py
│  │  │  │  │  ├─ authlog.py
│  │  │  │  │  ├─ reports.py
│  │  │  │  │  └─ health.py
│  │  │  │  └─ __init__.py
│  │  │  └─ __init__.py
│  │  ├─ core/
│  │  │  ├─ config.py
│  │  │  └─ security.py
│  │  ├─ models/
│  │  │  ├─ nmap_models.py
│  │  │  ├─ authlog_models.py
│  │  │  └─ report_models.py
│  │  ├─ services/
│  │  │  ├─ nmap_parser.py
│  │  │  ├─ authlog_parser.py
│  │  │  ├─ ai_summarizer.py
│  │  │  └─ report_generator.py
│  │  ├─ templates/
│  │  │  └─ report_template.html
│  │  ├─ static/
│  │  │  ├─ css/
│  │  │  │  └─ styles.css
│  │  │  └─ js/
│  │  │     └─ chart-config.js
│  │  ├─ main.py
│  │  └─ __init__.py
│  ├─ tests/
│  │  ├─ test_nmap.py
│  │  ├─ test_authlog.py
│  │  └─ test_reports.py
│  ├─ requirements.txt
│  └─ README.md
│
├─ frontend/
│  ├─ web/
│  └─ README.md
│
├─ data/
│  ├─ examples/
│  │  ├─ nmap/
│  │  └─ authlog/
│  └─ README.md
│
├─ reports/
│  ├─ html/
│  ├─ markdown/
│  └─ pdf/
│
├─ docs/
│  ├─ architecture.md
│  ├─ api_design.md
│  └─ hackathon_notes.md
│
├─ .gitignore
├─ .env.example
└─ README.md
