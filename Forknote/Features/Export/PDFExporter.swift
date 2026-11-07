import ForknoteCore
import SwiftUI
import UIKit

enum PDFExporter {
    static func write(_ report: ClinicianReport) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Forknote-Food-Symptom-Log.pdf")
        try render(report).write(to: url, options: .atomic)
        return url
    }

    private static func render(_ report: ClinicianReport) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Forknote food and symptom log",
            kCGPDFContextCreator as String: "Forknote",
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)
        return renderer.pdfData { context in
            let margin: CGFloat = 54
            let bottom: CGFloat = 64
            var y = margin

            func startPage() {
                context.beginPage()
                y = margin
                let footer = "Forknote · a personal log, not a medical device"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor(white: 0.35, alpha: 1),
                ]
                let footerRect = CGRect(x: margin, y: page.height - 36, width: page.width - margin * 2, height: 14)
                (footer as NSString).draw(in: footerRect, withAttributes: attrs)
            }

            func draw(_ text: String, font: UIFont) {
                if text.isEmpty {
                    y += 10
                    return
                }
                let style = NSMutableParagraphStyle()
                style.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(white: 0.1, alpha: 1),
                    .paragraphStyle: style,
                ]
                let width = page.width - margin * 2
                let bounds = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs,
                    context: nil
                )
                let height = ceil(bounds.height)
                if y + height > page.height - bottom {
                    startPage()
                }
                (text as NSString).draw(
                    in: CGRect(x: margin, y: y, width: width, height: height),
                    withAttributes: attrs
                )
                y += height + 4
            }

            startPage()
            let lines = report.plainText.components(separatedBy: "\n")
            for (index, line) in lines.enumerated() {
                let font = index == 0
                    ? UIFont.systemFont(ofSize: 18, weight: .semibold)
                    : UIFont.systemFont(ofSize: 12)
                draw(line, font: font)
            }
        }
    }
}

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct ActivitySheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {
        guard let popover = controller.popoverPresentationController else { return }
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
        popover.permittedArrowDirections = []
    }
}
