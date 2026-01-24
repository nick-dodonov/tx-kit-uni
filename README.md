# Uni Kit

Configurations, settings, and tools to set up build, debug, or development assistance, shared between repositories.
Git subtree or git submodules can also be used for this purpose.

## Working with Repository 

### As Git subtree
```bash
# Add the remote repository
git remote add tx-kit-uni git@github.com:nick-dodonov/tx-kit-uni.git

# Add the subtree
git subtree add --prefix=uni tx-kit-uni main --squash

# Update the subtree later
git subtree pull --prefix=uni tx-kit-uni main --squash

# Pushing changes back to upstream
git subtree push --prefix=uni tx-kit-uni main
```

### As Git submodule

```bash
# Add the remote repository
git submodule add git@github.com:nick-dodonov/tx-kit-uni.git uni

...
```
