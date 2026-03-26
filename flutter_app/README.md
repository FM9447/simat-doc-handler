# DocTransit - Flutter Frontend

Digital Student Document Handler for SIMAT Smart Campus.

## Features
- Secure document submission and tracking.
- Progress monitoring and push notifications.
- Professional PDF generation for official transcripts and letters.

## Getting Started

1.  **Dependencies**: Run `flutter pub get` in the `flutter_app` directory.
2.  **Firebase**: Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present in their respective app folders.
3.  **Branding**: All assets (icons, splash, loading) use the custom **DocTransit** design.

## Platform Support

- **Android/iOS**: Native builds support full push notification integration.
- **Web**: Optimized for hosting on GitHub Pages or custom domains (e.g., doctransit.live).

## Automated Deployment (GitHub Actions)

This project is configured with a centralized GitHub Actions workflow located at `.github/workflows/main_doctransit.yml`.

- **Trigger**: Pushes to `main` or `master` branches.
- **Action**: Automatically builds and deploys the latest web version to the `gh-pages` branch.
- **Manual Step**: If the workflow file is not automatically pushed due to token restrictions, manually create it on GitHub using the content provided in the project root.

## Troubleshooting

- **Asset Loading (Web)**: If `AssetManifest.bin.json` fails to load, verify the `base href` in `index.html`. We have implemented a robust detection script to handle standard deployment paths.
- **Fonts (Web)**: Noto Sans is loaded via Google Fonts in the `index.html` head to prevent missing character warnings.