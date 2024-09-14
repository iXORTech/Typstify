<h1 align="center">Typstify</h1>

<p align="center"> 
  <b>A Typst Editor for iPad</b>
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-AGPL--3.0--or--later-important?style=for-the-badge" />
  </a>
</p>

> [!IMPORTANT]
> Typstify is currently **NOT** in active development as my other projects and school works has a relatively higher priority. But, I am still working on Typstify bit by bit.
>
> \- @Cubik65536 (Developer)

> [!IMPORTANT]
> Typstify is currently in development and not yet recommended for production use. You can test-drive the current in development version by building the app on your own and run it.
>
> The app is not available on App Store or TestFlight yet. As there's major issues related to performance and some important feature are not refined, there's currently no plan to release this app on App Store or TestFlight.

## Motivation

Typst, designed as an alternative for LaTeX, can be very useful for students for taking notes due to its simplicity. However, it is difficult to draw quick sketches. It is possible for drawing stuff in Typst, but they are often too complicated when a precise figure is not needed (e.g. when we want to draw a quick visual representation of some math concepts). Typstify is designed to meet the needs of being able to draw anything and insert it into the Typst document by integrating [PencilKit](https://developer.apple.com/documentation/pencilkit) into the app.

## Roadmap

- [x] Basic Typst Editing
- [x] Real-Time PDF Preview
- [x] Real-Time Syntax Error Check
- [x] Access to Online Packages
- [ ] Image Insertion
- [ ] Syntax Highlighting
- [ ] Sketching
- [ ] Drag-and-Drop Support
- [ ] PDF Export
- [ ] Project Import/Export
- [ ] Templates Support
- [ ] Support for Additional Fonts

## Building the App

### Requirements

- macOS Ventura 13.5 or later
- Rust 1.80.0 or later
- [cargo-lipo](https://github.com/TimNN/cargo-lipo)
- Xcode 15.0 or later
- iPadOS 17.0 or later

### Build

Open the Xcode project via `Typstify/Typstify.xcodeproj`, and then build.

`src` contains all Rust codes for using Typst library in Swift.

`Typstify` contains all codes and resources for the iPadOS app.

If you just need to build the Rust module and the bridge, run `PROJECT_DIR="${PWD}/Typstify" ./Typstify/build-rust.sh` in the project root.

## Help Needed

As of now, some help are needed to get the application into an usable state:

- an app icon is missing
- features are not completed and bugs has to be fixed
- code optimization is needed

and all contribution related to solving these problems are very welcomed!

## Credits & Acknowledgments

This project relies on these open source projects:

- [Typst Libraries](https://crates.io/crates/typst) for [Typst](https://typst.app) related functionality such as Typst document rendering and syntax check.
- [tfachmann/typst-as-library](https://github.com/tfachmann/typst-as-library) for providing a wrapper around the Typst Library.
- [chinedufn/swift-bridge](https://github.com/chinedufn/swift-bridge) for enabling Swift-Rust interoperability.
- [mchakravarty/CodeEditorView](https://github.com/mchakravarty/CodeEditorView): A SwiftUI code editor view for iOS, visionOS, and macOS
- [mchakravarty/ProjectNavigator](https://github.com/mchakravarty/ProjectNavigator): A SwiftUI project navigation view for macOS and iOS

Some fonts are embedded into `typst-library-swift` for rendering the document. This might change when further font support is added. All the embedded fonts are licensed under the [SIL Open Font License](https://openfontlicense.org/), they are:

- [CMU* Concrete](https://fontlibrary.org/en/font/cmu-concrete)
- [CMU* Sans Serif](https://fontlibrary.org/en/font/cmu-sans-serif)
- [CMU* Serif](https://fontlibrary.org/en/font/cmu-serif)
- [CMU* Typewriter](https://fontlibrary.org/en/font/cmu-typewriter)
- [IBM Plex Mono](https://www.ibm.com/plex/)
- [IBM Plex Sans](https://www.ibm.com/plex/)
- [IBM Plex Serif](https://www.ibm.com/plex/)
- [STIX Two Math](https://stixfonts.org/)
- [LXGW WenKai Mono Lite](https://github.com/lxgw/LxgwWenKai-Lite)

\* CMU stands for Computer Modern Unicode, which is a [derivative of the Computer Modern font family](https://en.wikipedia.org/wiki/Computer_Modern).

By default, the fonts always falls backs to:

- STIX Two Math for mathematical formulas
- IBM Plex Mono for raw text (e.g. code)
- IBM Plex Sans and LXGW WenKai Mono Lite for normal text (LXGW WenKai Mono Lite is used for characters that are not supported by IBM Plex Sans, such as Chinese characters)
