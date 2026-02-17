import SwiftUI

struct HealthPermissionsView: View {
    let healthManager: HealthManager
    @Binding var hasCompletedOnboarding: Bool
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red.gradient)

            VStack(spacing: 12) {
                Text("Trends")
                    .font(.largeTitle.bold())

                Text("Visualize your health data with\nbeautiful charts and insights.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                PermissionRow(
                    icon: "figure.walk",
                    color: .green,
                    title: "Activity & Fitness",
                    description: "Steps, calories, exercise, distance"
                )
                PermissionRow(
                    icon: "scalemass.fill",
                    color: .purple,
                    title: "Body Measurements",
                    description: "Weight, BMI, body fat"
                )
                PermissionRow(
                    icon: "heart.fill",
                    color: .red,
                    title: "Vitals & Sleep",
                    description: "Heart rate, HRV, sleep, respiratory"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                requestAccess()
            } label: {
                if isRequesting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                } else {
                    Text("Allow Health Access")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestAccess() {
        isRequesting = true
        Task {
            do {
                try await healthManager.requestAuthorization()
            } catch {
                // HealthKit authorization errors are non-fatal;
                // denied types simply return no data
            }
            hasCompletedOnboarding = true
            isRequesting = false
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
