# Changelog

Ce projet suit le format Keep a Changelog.
Toutes les versions suivent le format SemVer.

---

## [2.0.0] – 2025-11-23
### Added
- Support ARM64
- Ajout des clés au format PPK (connexion Windows)
- Ajout de 2 scripts automatiques pour générer les fichiers .BAT de connexion
- Ajout de scripts prêts à l’emploi dans `home/scripts`
- Ajout de Midnight Commander (mc)
- Refonte complète du README

### Improved
- UX utilisateur (connexion simplifiée)
- Organisation interne du dossier `/data`
- Documentation générale

---

## [1.5.0] – 2025-11-22
### Added
- Permissions renforcées sur `/data/config/*`
- Outils MKV ajoutés : `mkvtoolnix`, `mkvinfo`
- Support Intel VAAPI
- Compatibilité simultanée NVIDIA + Intel

### Fixed
- configuration de permission interne

---

## [1.4.0] – 2025-11-21
### Added
- Génération automatique de clés SSH
- Nouvelle variable `KEY_VAR`
- Nouvelle variable `USERS_VAR`
- Création automatique des homes utilisateurs
- Génération automatique des clés SSH par utilisateur

---

## [1.3.0] – 2025-11-21
### Added
- Support complet SFTP
- Authentification par clé publique
- Options SSH configurées via variables ENV
- Désactivation du mot de passe root

---

## [1.2.0] – 2025-11-20
### Added
- Support GPU via NVIDIA runtime
- Variables `NVIDIA_VISIBLE_DEVICES`
- Accélération hardware via FFmpeg NVENC

---

## [1.1.0] – 2025-11-20
### Added
- Volume `/data`
- Première arborescence utilisateur
- premiers scripts internes simples

---

## [1.0.0] – 2025-11-19
### Initial release
- FFmpeg statique
- Debian minimal
- Sans SSH
- Sans GPU
- Sans gestion utilisateurs