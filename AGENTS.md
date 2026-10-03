# Agent context for this lab

On the original lab host, read `.agent/README.md` before changing VM state.
That directory and `.exercises/` are local-only and ignored by Git; they may
not exist in another checkout. Do not copy local credentials or course PDFs
into tracked files or GitHub commits.

Use `README.md` for portable setup instructions. Check live libvirt state and
the guest network configuration before changing existing VMs: this project has
gone through several Windows Server versions, and creation scripts skip VMs
that are already defined.
