import SwiftUI

struct LoginView: View {
  @ObservedObject var store: HouseStore
  @State private var email = ""
  @State private var password = ""
  @FocusState private var focusedField: Field?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private enum Field { case email, password }
  private var canConnect: Bool {
    !store.busy && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !password.isEmpty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      HStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("BEM-VINDO").font(.system(size: 10, weight: .semibold)).tracking(2)
            .foregroundStyle(HouseTheme.ice)
          Text("Sua casa,\nno Mac.").font(.system(size: 34, weight: .semibold))
        }
        Spacer(minLength: 0)
        Image(systemName: "house.fill").font(.system(size: 34, weight: .light))
          .foregroundStyle(.white).frame(width: 80, height: 80)
          .background(
            LinearGradient(
              colors: [HouseTheme.ice, HouseTheme.blue],
              startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 25)
          )
          .overlay(RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.25)))
          .shadow(color: HouseTheme.blue.opacity(0.3), radius: 22, y: 6)
          .accessibilityHidden(true)
      }.padding(.top, 4)
      Text("Conecte a mesma conta do aplicativo Positivo Casa Inteligente.")
        .font(.system(size: 14)).foregroundStyle(HouseTheme.secondary).fixedSize(
          horizontal: false, vertical: true)

      if store.hasSavedLogin {
        VStack(alignment: .leading, spacing: 12) {
          Label("Seu acesso está salvo", systemImage: "key.fill")
            .font(.system(size: 13, weight: .medium)).foregroundStyle(HouseTheme.ice)
          Text("Tente reconectar sem digitar sua senha novamente.")
            .font(.system(size: 12)).foregroundStyle(HouseTheme.secondary)
          HStack(spacing: 16) {
            Button("Tentar reconectar") { Task { await store.restoreLogin() } }
            Button("Desconectar", action: store.disconnect)
          }.font(.system(size: 12, weight: .medium)).buttonStyle(.borderless)
            .tint(HouseTheme.ice).disabled(store.busy || store.sending)
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
          .background(HouseTheme.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
          .overlay(RoundedRectangle(cornerRadius: 20).stroke(HouseTheme.border))
      }

      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Text("Acesso à sua casa").font(.system(size: 16, weight: .semibold))
          Spacer()
          Image(systemName: "lock.shield").foregroundStyle(HouseTheme.ice)
        }
        field(title: "E-mail", icon: "envelope", kind: .email) {
          TextField("seu@email.com", text: $email).textContentType(.username)
            .autocorrectionDisabled().focused($focusedField, equals: .email)
            .onSubmit { focusedField = .password }.accessibilityLabel("E-mail")
        }
        field(title: "Senha", icon: "lock", kind: .password) {
          SecureField("Senha do aplicativo", text: $password).textContentType(.password)
            .focused($focusedField, equals: .password).onSubmit(connect).accessibilityLabel("Senha")
        }
        Button(action: connect) {
          HStack(spacing: 10) {
            if store.busy { ProgressView().controlSize(.small).tint(.white) }
            Text(store.busy ? "Conectando…" : "Conectar sua casa")
              .font(.system(size: 14, weight: .semibold))
            if !store.busy {
              Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
            }
          }.foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
            .background(
              LinearGradient(
                colors: [HouseTheme.blue, HouseTheme.blue.opacity(0.65)],
                startPoint: .topLeading, endPoint: .bottomTrailing),
              in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HouseTheme.ice.opacity(0.25)))
        }.buttonStyle(RemoteButtonStyle()).disabled(!canConnect).opacity(canConnect ? 1 : 0.45)
      }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(
          LinearGradient(
            colors: [HouseTheme.surface, HouseTheme.surface.opacity(0.5)],
            startPoint: .topLeading, endPoint: .bottomTrailing),
          in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(HouseTheme.border))

      HStack(alignment: .top, spacing: 10) {
        Image(systemName: "checkmark.shield").font(.system(size: 17)).foregroundStyle(
          HouseTheme.ice)
        Text("Seu acesso fica protegido no Chaves deste Mac e é removido ao desconectar.")
          .font(.system(size: 12)).foregroundStyle(HouseTheme.secondary)
      }.padding(.horizontal, 4)
      Text("Integração independente · login por HTTPS na nuvem Positivo.")
        .font(.system(size: 11)).foregroundStyle(HouseTheme.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }.animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: focusedField)
  }

  private func field<Content: View>(
    title: String, icon: String, kind: Field, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(HouseTheme.secondary)
      HStack(spacing: 12) {
        Image(systemName: icon).font(.system(size: 16)).foregroundStyle(HouseTheme.ice).frame(
          width: 20
        )
        .accessibilityHidden(true)
        content().textFieldStyle(.plain).font(.system(size: 14)).foregroundStyle(.white)
      }.padding(.horizontal, 14).frame(height: 48)
        .background(HouseTheme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
          RoundedRectangle(cornerRadius: 14).stroke(
            focusedField == kind ? .white.opacity(0.5) : HouseTheme.border)
        )
        .disabled(store.busy)
    }
  }

  private func connect() {
    guard canConnect else { return }
    let value = password
    password = ""
    Task { await store.connect(email: email, password: value) }
  }
}
