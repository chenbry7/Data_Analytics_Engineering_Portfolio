# Documentation

This documentation describes the sales warehouse implementation, its design decisions, operating workflow, and analytical use. The project runs on SQL Server with CSV inputs, full-refresh Bronze/Silver tables, and analytical Gold views.

## Start Here

| Document | Purpose |
|---|---|
| [Architecture and diagrams](architecture.md) | System architecture, end-to-end lineage, integration keys, and the sales mart |
| [Architecture decisions](architecture_decisions.md) | Warehouse purpose, architecture alternatives, separation of concerns, and selected tradeoffs |
| [Source system analysis](source_system_analysis.md) | Source ownership, integration interface, file scope, access, and extraction considerations |
| [Source and Silver catalog](source_data_catalog.md) | File profiles and physical Bronze/Silver column definitions |
| [Layer design and delivery](data_layers.md) | Layer comparison and Bronze, Silver, and Gold development workflows |
| [ETL methods and transformations](etl_design.md) | Extraction/loading methods, actual cleaning rules, validation, and error behavior |
| [Data modeling](data_modeling.md) | Conceptual/logical/physical models, star versus snowflake, facts, dimensions, and keys |
| [Gold data catalog](data_catalog.md) | Every analytical view column, type, and business definition |
| [Analytics guide](analytics_guide.md) | Profiling, magnitude, trends, cumulative analysis, comparisons, proportions, and segmentation |
| [Development and operating workflow](development_workflow.md) | Git, ingestion choices, setup, recurring refresh, and maintenance |
| [Naming conventions](naming_conventions.md) | Object, column, and procedure naming |
| [Project capabilities](project_extensions.md) | Reliability fixes, scorecard, report definitions, and focused regression checks |
| [Verification results](validation.md) | Full pipeline execution, reconciled counts, repeatability, and failure-path checks |
| [Analysis findings](analysis_findings.md) | Executed results with interpretation and validation boundaries |
| [Development scope](engineering_roadmap.md) | Implemented capabilities and explicit scope boundaries |

## Topic Map

| Topic | Location |
|---|---|
| Why a warehouse; operational sources versus analytical access | Architecture decisions: purpose |
| Warehouse, lake, lakehouse, mesh | Architecture decisions: architecture families |
| Inmon, Kimball, Data Vault, Medallion | Architecture decisions: modeling and organization approaches |
| Separation of concerns | Architecture decisions: responsibility boundaries |
| High-level architecture | Architecture and diagrams: architecture |
| Source ownership, interfaces, extraction, history, volume, authentication | Source system analysis |
| Bronze/Silver/Gold definitions, goals, object types, load strategy, transformations, modeling, audiences | Layer design and delivery: comparison |
| Analyze → build → validate → document for all three layers | Layer design and delivery: workflows |
| Extraction, transformation, load; full/incremental; batch/stream; SCD | ETL methods and transformations |
| Source-to-target lineage | Architecture and diagrams: lineage |
| Source joins and key normalization | Architecture and diagrams: integration; ETL transformation matrix |
| Conceptual, logical, and physical models | Data modeling |
| Star/snowflake; dimensions/facts; surrogate keys | Data modeling |
| Catalog purpose and consumers | Data modeling: catalog; Gold catalog |
| Git collaboration and version history | Development and operating workflow |
| Bulk loading versus ordinary inserts | Development and operating workflow |
| Dimensions versus measures | Analytics guide: field classification |
| Dimension/date/measure exploration | Analytics guide: exploration |
| Magnitude, change over time, cumulative, performance, part-to-whole, segmentation | Analytics guide: analysis patterns |

## Implementation Status

Architecture documents describe the checked-in SQL. Comparative design patterns explain alternatives and are not additional deployed systems. The analytics guide provides optional read-only examples; executed deliverables are scripts 13 and 14 and the results documented in Analysis Findings. SVG and Mermaid assets are available in [diagrams/](diagrams/).
