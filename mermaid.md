flowchart TD
    A[Start] --> B{Active timeline?}
    B -->|Yes| C[Display timeline]
    B -->|No| D{Timeline collection URL?}
    D -->|Yes| E[Display timeline collection]
    E -->|Select, fetch and save timeline| C
    D -->|No| F[Enter timeline collection URL]
    F --> E