# Data Source and Schema

## Provenance

Statistics source: **NBA.com**, 2023–24 NBA player statistics. The included `nba_2023_24_stats.csv` was supplied through the University of Toronto STA437 Project 1 materials. The original report cites dataset documentation by J. S. Speagle (2026); that separate document is not included here. The exact extraction date and original query parameters are unavailable.

The snapshot contains **572 rows and 67 columns**, with one unique player ID and name per row. Its SHA-256 is:

```text
d604caddec43b15e638ef366e0363df7f0c6335da95c6263ee539721070db611
```

## Fields Used

| Purpose | Fields |
| --- | --- |
| Player metadata | PLAYER_NAME, TEAM_ABBREVIATION, GP |
| Playing time | MIN |
| Scoring volume | PTS, FGM, FGA, FTM, FTA |
| Three-point profile | FG3M, FG3A, FG3_PCT |
| Shooting percentages | FG_PCT, FT_PCT |
| Rebounding | OREB, DREB, REB |
| Playmaking and defensive activity | AST, TOV, STL, BLK |

Statistics are per-game averages; percentages are fractions from 0 to 1. The analysis retains players with GP >= 10 and MIN >= 10, yielding 421 players. Source percentage encodings are retained; rounded zero-attempt values do not necessarily identify players with no season attempts. No selected observations are missing.

## Reproducing or Replacing the Input

The original input is included beside the notebook and requires no separate download. The last notebook cell checks its hash, dimensions and player uniqueness before recording validation results.

A replacement dataset can differ in rounding, season coverage, transfers or aggregation. It may not reproduce the published figures or 421-player sample. Review the snapshot-specific assertions and document any replacement before comparing results.

## Attribution and Usage

NBA statistics remain attributed to NBA.com. Public display and CSV inclusion were confirmed by the project author for this portfolio. No new license is granted to NBA statistics or course materials; this repository should not be read as establishing a general open-data license.

Source references: [NBA Stats](https://www.nba.com/stats), [statistic definitions](https://www.nba.com/stats/help/glossary), [NBA terms](https://www.nba.com/termsofuse), and [NBA Stats FAQ](https://www.nba.com/stats/help/faq). Usage references were reviewed on 2026-10-01.
