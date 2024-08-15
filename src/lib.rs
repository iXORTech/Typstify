use std::fmt::Display;
use typst::{eval::Tracer, layout::Abs};
use typst::foundations::Smart;
use typst::model::Document;
use swift_bridge;

mod typst_wrapper_world;


#[swift_bridge::bridge]
mod ffi {
    enum SourceDiagnosticResultSeverity {
        Error,
        Warning,
    }

    extern "Rust" {
        type SourceDiagnosticResult;

        fn message(&self) -> String;
        fn severity(&self) -> SourceDiagnosticResultSeverity;
        fn line_start(&self) -> u64;
        fn column_start(&self) -> u64;
        fn line_end(&self) -> u64;
        fn column_end(&self) -> u64;
    }

    extern "Rust" {
        type FailedToSetWorkingDirectory;

        fn message(&self) -> String;
    }

    extern "Rust" {
        type FailedToGetWorkingDirectory;

        fn message(&self) -> String;
    }

    extern "Rust" {
        type TypstCompilationError;

        fn message(self: &TypstCompilationError) -> String;
        fn diagnostics(self: &TypstCompilationError) -> Vec<SourceDiagnosticResult>;

        fn get_rendered_document_svg(source: String) -> Result<String, TypstCompilationError>;
        fn get_rendered_document_pdf(source: String) -> Result<Vec<u8>, TypstCompilationError>;
        fn set_working_directory(path: String) -> Result<(), FailedToSetWorkingDirectory>;
        fn get_working_directory() -> Result<String, FailedToGetWorkingDirectory>;
    }
}

use ffi::SourceDiagnosticResultSeverity;

#[derive(Clone)]
pub struct SourceDiagnosticResult {
    pub message: String,
    pub severity: SourceDiagnosticResultSeverity,
    pub line_start: u64,
    pub column_start: u64,
    pub line_end: u64,
    pub column_end: u64,
}

impl SourceDiagnosticResult {
    fn new(source: &typst::syntax::Source, e: &typst::diag::SourceDiagnostic) -> Self {
        // Line number `-3` to account for the `add_fallback_font` function
        // Line number `+1` so that the line number starts from `1`
        let range = source.range(e.span).unwrap_or(0..0);
        let line_start = (source.byte_to_line(range.start).unwrap_or(3) - 3 + 1) as u64;
        let column_start = source.byte_to_column(range.start).unwrap_or(0) as u64;
        let line_end = (source.byte_to_line(range.end).unwrap_or(3) - 3 + 1) as u64;
        let column_end = source.byte_to_column(range.end).unwrap_or(0) as u64;

        Self {
            message: e.message.to_string(),
            severity: match e.severity {
                typst::diag::Severity::Error => SourceDiagnosticResultSeverity::Error,
                typst::diag::Severity::Warning => SourceDiagnosticResultSeverity::Warning,
            },
            line_start,
            column_start,
            line_end,
            column_end,
        }
    }

    pub fn message(&self) -> String {
        self.message.clone()
    }

    pub fn severity(&self) -> SourceDiagnosticResultSeverity {
        self.severity.clone()
    }

    pub fn line_start(&self) -> u64 {
        self.line_start
    }

    pub fn column_start(&self) -> u64 {
        self.column_start
    }

    pub fn line_end(&self) -> u64 {
        self.line_end
    }

    pub fn column_end(&self) -> u64 {
        self.column_end
    }
}

pub struct TypstCompilationError {
    source_diagnostic_results: Vec<SourceDiagnosticResult>,
}

impl TypstCompilationError {
    pub fn message(&self) -> String {
        let mut message = String::new();
        message.push_str("Typst Compilation Failed. Diagnostics:\n");
        for diagnostic in &self.source_diagnostic_results {
            let severity = match diagnostic.severity {
                SourceDiagnosticResultSeverity::Error => "Error",
                SourceDiagnosticResultSeverity::Warning => "Warning",
            };

            message.push_str(&format!(
                "\t- [{:?}] {}. Line: {}, Column: {}.\n",
                severity, diagnostic.message,
                diagnostic.line_start, diagnostic.column_start,
            ));
        }
        message
    }

    pub fn diagnostics(&self) -> Vec<SourceDiagnosticResult> {
        self.source_diagnostic_results.clone()
    }
}

impl Display for TypstCompilationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message())
    }
}

// Temporarily disabled due to lack of support in the Swift Bridge used.
// #[derive(Debug)]
// enum FileManagementError {
//     FailedToSetWorkingDirectory { path: String },
//     FailedToGetWorkingDirectory { error: String },
// }

pub struct FailedToSetWorkingDirectory {
    path: String,
}

impl FailedToSetWorkingDirectory {
    pub fn message(&self) -> String {
        let mut message = String::new();
        message.push_str("Failed to set working directory to ");
        message.push_str(&self.path);
        message
    }
}

impl Display for FailedToSetWorkingDirectory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message())
    }
}

pub struct FailedToGetWorkingDirectory {
    error: String,
}

impl FailedToGetWorkingDirectory {
    pub fn message(&self) -> String {
        let mut message = String::new();
        message.push_str("Failed to get working directory. Error: ");
        message.push_str(&self.error);
        message
    }
}

impl Display for FailedToGetWorkingDirectory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message())
    }
}

fn add_fallback_font(source: String) -> String {
    format!(
        "#show math.equation: set text(font: \"STIX Two Math\")\
        \n#show raw: set text(font: \"IBM Plex Mono\")\
        \n#set text(font: (\"IBM Plex Sans\", \"LXGW WenKai Mono Lite\"))\
        \n{}",
        source
    )
}

fn get_rendered_document(source: String) -> Result<Document, TypstCompilationError> {
    let source = add_fallback_font(source);

    let world = typst_wrapper_world::TypstWrapperWorld::new(
        "./".to_owned(), source,
    );

    // Render document
    let mut tracer = Tracer::default();

    let r = typst::compile(&world, &mut tracer);

    match r {
        Ok(document) => Ok(document),
        Err(e) => {
            let source_diagnostic_results = e.iter().map(
                |e| SourceDiagnosticResult::new(
                    &world.get_source_ref(), e,
                )
            ).collect();
            Err(TypstCompilationError { source_diagnostic_results })
        }
    }
}

pub fn get_rendered_document_svg(source: String) -> Result<String, TypstCompilationError> {
    // Render SVG and return the SVG string
    Ok(typst_svg::svg_merged(&get_rendered_document(source)?, Abs::pt(2.0)))
}

pub fn get_rendered_document_pdf(source: String) -> Result<Vec<u8>, TypstCompilationError> {
    // Render PDF and return the PDF bytes
    Ok(typst_pdf::pdf(&get_rendered_document(source)?, Smart::Auto, None))
}

pub fn set_working_directory(path: String) -> Result<(), FailedToSetWorkingDirectory> {
    let decoded = urlencoding::decode(&path);
    if decoded.is_err() {
        return Err(FailedToSetWorkingDirectory { path });
    }
    let r = std::env::set_current_dir(decoded.unwrap().into_owned());
    match r {
        Ok(_) => Ok(()),
        Err(_) => Err(FailedToSetWorkingDirectory { path }),
    }
}

pub fn get_working_directory() -> Result<String, FailedToGetWorkingDirectory> {
    let r = std::env::current_dir();
    match r {
        Ok(path) => {
            match path.to_str() {
                Some(path_str) => Ok(path_str.to_owned()),
                None => Err(FailedToGetWorkingDirectory {
                    error: "Failed to convert path to string.".to_owned()
                }),
            }
        }
        Err(err) => Err(FailedToGetWorkingDirectory {
            error: err.to_string()
        }),
    }
}
