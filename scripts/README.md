# AWS Helper Scripts

This directory contains helpful scripts for AWS infrastructure management and automation.

## Available Scripts

| Script | Description |
|--------|-------------|
| `awscheck.sh` | Checks AWS configuration and credentials |

## Using the Scripts

### awscheck.sh

This script verifies your AWS configuration and connection status.

```bash
# Give execute permission (Linux/macOS)
chmod +x ./awscheck.sh

# Run the script
./awscheck.sh
```

For Windows PowerShell:
```powershell
# Run with bash (if WSL/Git Bash installed)
bash ./awscheck.sh

# OR using PowerShell directly (may require adjustments)
./awscheck.sh
```

## Adding New Scripts

When adding new scripts to this directory:

1. Use descriptive names with `.sh` extension
2. Include a header comment explaining purpose and usage
3. Add proper error handling
4. Update this README with script details
5. Consider portability between Linux/macOS/Windows environments

## Best Practices

- Always include error handling in scripts
- Use environment variables for configuration when possible
- Document parameters and return values
- Maintain backward compatibility when updating scripts
- Include examples in script headers

## Related Projects

 