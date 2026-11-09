import SwiftData
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SolutionRoute: Hashable {
    let id: UUID
}

struct SolutionLoaderView: View {
    let problemID: UUID
    @Query private var problems: [SolvedProblem]

    var body: some View {
        Group {
            if let problem = problems.first(where: { $0.id == problemID }) {
                if let solution = problem.solution {
                    SolutionDetailView(problem: problem, solution: solution)
                } else {
                    ContentUnavailableView(
                        "Решение недоступно",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Сохранённые данные повреждены или имеют старый формат.")
                    )
                }
            } else {
                ContentUnavailableView(
                    "Задача не найдена",
                    systemImage: "questionmark.folder",
                    description: Text("Возможно, она была удалена из истории.")
                )
            }
        }
        .background(PhysoraBackground())
        .navigationBarTitleDisplayMode(.inline)
    }
}
