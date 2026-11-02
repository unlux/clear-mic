# Security policy

Security fixes are supported on the latest tagged release on a best-effort basis.
Clear Mic is experimental and carries no response-time or support guarantee.

Report vulnerabilities privately to lakshaychoudhary77712@gmail.com. Include the
release version, macOS version, reproduction steps and likely impact. Do not
send recordings, secrets, SDK license tokens or installation identifiers.
Please do not post an unpatched vulnerability or personal data in a public issue.

The normal app processes audio locally, while its model SDK makes the network
requests described in PRIVACY.md. Dependencies are pinned in Package.resolved.
Release archives have SHA-256 checksums, are ad-hoc signed, and are not notarized
by Apple. A matching checksum checks file integrity, not software trustworthiness.
