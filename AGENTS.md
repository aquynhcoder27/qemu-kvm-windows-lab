# Agent context for this lab

On the original lab host, read `.agent/README.md` before changing VM state.
That directory and `.exercises/` are local-only and ignored by Git; they may
not exist in another checkout. Do not copy local credentials or course PDFs
into tracked files or GitHub commits.

Use `README.md` for the current three-VM lab and `evidence/README.md` for
exercise evidence. Check live libvirt state and the guest network configuration
before changing existing VMs: this project has gone through several Windows
Server versions, and creation scripts skip VMs that are already defined.

Work from a named exercise in `.exercises/`; its PDFs are local-only. Read the
exercise's topology and requirements before applying its old IP addresses or
commands. The three BKAP manuals target Server 2012, while the live server is
2008 R2. Capture screenshots and record what each one proves in `evidence/`.
