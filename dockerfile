FROM swift:5.9-jammy as builder

WORKDIR /app
COPY Package.swift .
RUN swift package resolve

COPY . .
RUN swift build -c release

FROM swift:5.9-jammy-slim
WORKDIR /app
COPY --from=builder /app/.build/release/Run /app/Run
COPY --from=builder /app/.build/release/App /app/App

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]