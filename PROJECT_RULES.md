# PROJECT DEVELOPMENT RULES

## 1. Project understanding
- Always understand the project's purpose before making changes.
- Follow the approved requirements and technical documentation.
- Do not invent or silently change business requirements.
- Treat approved project documents as the source of truth.

## 2. Architecture
- Follow the existing architecture.
- Respect existing technology choices.
- Use modular and maintainable code.
- Reuse existing components and services.
- Avoid unnecessary dependencies and abstractions.
- Do not introduce a new architectural pattern without justification.

## 3. Implementation
- Inspect existing files before modifying them.
- Implement one approved feature at a time.
- Make the smallest reasonable changes.
- Do not rewrite working functionality unnecessarily.
- Do not leave incomplete placeholder implementations.
- Do not generate fake data for real production functionality.

## 4. Code quality
- Use meaningful names.
- Follow consistent formatting.
- Avoid duplicated business logic.
- Use appropriate types.
- Keep functions and components focused.
- Handle errors appropriately.
- Add comments where they provide useful context.

## 5. Security
- Never expose API keys, passwords, or credentials.
- Keep secrets in secure server-side configuration.
- Validate inputs on the server.
- Enforce authentication and authorization.
- Follow least-privilege access principles.
- Avoid exposing sensitive user information.
- Do not trust frontend validation as a security boundary.

## 6. Database and APIs
- Follow the approved database schema.
- Respect existing API contracts.
- Never invent API endpoints or response structures.
- Handle loading, empty, error, and success states.
- Use appropriate validation and error handling.
- Avoid destructive database changes without explicit approval.

## 7. UI/UX
- Follow the approved design system.
- Maintain consistent spacing, typography, and colors.
- Build responsive interfaces.
- Prioritize accessibility and usability.
- Reuse existing components.
- Never introduce unrelated visual changes.

## 8. Testing
- Add tests for new functionality.
- Test positive and negative scenarios.
- Test important edge cases.
- Run relevant tests after every feature.
- Fix regressions before proceeding.
- Never claim a test passed without actually running it.

## 9. Git and version control
- Preserve existing work.
- Review changes before committing.
- Avoid unrelated file modifications.
- Maintain clear commit messages.
- Never remove important project history.

## 10. Documentation
- Keep requirements and architecture documentation updated.
- Document important technical decisions.
- Update API and database documentation when necessary.
- Keep the development roadmap synchronized with actual progress.

## 11. Working procedure

For every development task:

1. Read PROJECT_RULES.md.
2. Read relevant project documentation.
3. Inspect affected source files.
4. Understand dependencies.
5. Prepare an implementation plan.
6. Identify expected file changes.
7. Wait for approval before significant implementation.
8. Implement only the requested task.
9. Run relevant tests.
10. Review changes and report results.

## 12. Completion report

After every task, report:

- Task completed.
- Requirements covered.
- Files created.
- Files modified.
- Important decisions.
- Tests executed.
- Actual test results.
- Remaining issues.

FINAL RULE:

Correctness, security, maintainability, and requirement compliance are more important than generating code quickly.

Do not implement the entire project in one operation.
