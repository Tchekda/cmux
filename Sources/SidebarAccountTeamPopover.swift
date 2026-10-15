import CmuxAppKitSupportUI
import SwiftUI

/// The compact sidebar account button for account-level actions.
struct SidebarAccountMenuButton: View {
    private var accountFlow: HostAccountFlow? { AppDelegate.shared?.auth?.accountFlow }
    private let title = String(localized: "settings.section.account", defaultValue: "Account")
    private let signInTitle = String(localized: "settings.account.signIn", defaultValue: "Sign In…")
    private let buttonSize = SidebarFooterButtonMetrics.buttonSize
#if DEBUG
    @AppStorage(SidebarFooterProfileIconDebugSettings.sizeKey)
    private var debugIconSize = SidebarFooterProfileIconDebugSettings.defaultSize
    @AppStorage(SidebarFooterProfileDisplayDebugSettings.displayKey)
    private var debugProfileDisplay = SidebarFooterProfileDisplayDebugSettings.defaultDisplay.rawValue
#endif

    private var profileIconSize: CGFloat {
#if DEBUG
        CGFloat(debugIconSize)
#else
        SidebarFooterButtonMetrics.profileIconSize
#endif
    }

    private var prefersProfileIcon: Bool {
#if DEBUG
        SidebarFooterProfileDisplayDebugChoice(rawValue: debugProfileDisplay) == .icon
#else
        false
#endif
    }

    private func presentation(
        isSignedIn: Bool,
        hasProfilePicture: Bool
    ) -> SidebarAccountButtonPresentation {
        let presentation = SidebarAccountButtonPresentation.resolve(
            isSignedIn: isSignedIn,
            prefersProfileIcon: prefersProfileIcon,
            hasProfilePicture: hasProfilePicture
        )
#if DEBUG
        if !presentation.showsProfilePicture {
            return SidebarAccountButtonPresentation(
                visual: presentation.visual,
                size: profileIconSize
            )
        }
#endif
        return presentation
    }

    var body: some View {
        let identity = accountFlow?.currentIdentity
        let isSignedIn = identity != nil
        let buttonTitle = isSignedIn ? title : signInTitle
        let profile = presentation(
            isSignedIn: isSignedIn,
            hasProfilePicture: identity?.avatarURL != nil
        )
        Menu {
            accountMenu
        } label: {
            SidebarAccountAvatar(
                avatarURL: identity?.avatarURL,
                displayName: identity?.displayName ?? "",
                email: identity?.email ?? "",
                isSignedIn: profile.showsProfilePicture,
                size: profile.size
            )
            .frame(width: buttonSize, height: buttonSize)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .disabled(accountFlow?.isWorkingOnAuth == true)
        .frame(width: buttonSize, height: buttonSize)
        .safeHelp(buttonTitle)
        .hintableAccessibilityLabel(buttonTitle, isEnabled: accountFlow?.isWorkingOnAuth != true)
        .accessibilityIdentifier("SidebarAccountMenuButton")
    }

    @ViewBuilder
    private var accountMenu: some View {
        if let identity = accountFlow?.currentIdentity {
            Text(identity.displayName.isEmpty ? identity.email : identity.displayName)
                .accessibilityIdentifier("SidebarAccountIdentity")
            if !identity.email.isEmpty && identity.email != identity.displayName {
                Text(identity.email)
                    .foregroundStyle(.secondary)
            }
            Divider()
            settingsMenuItem
            if let offer = accountFlow?.upgradeOffer {
                accountMenuItem(
                    title: ProUpgradePresenter.upgradeMenuTitle(for: offer),
                    systemImage: "sparkles",
                    accessibilityIdentifier: "SidebarAccountUpgradeButton"
                ) {
                    accountFlow?.openProUpgrade(source: .sidebarAccountMenu)
                }
            }
            accountMenuItem(
                title: String(localized: "cloud.teamPicker.switchAccount", defaultValue: "Switch Account…"),
                systemImage: "person.2",
                accessibilityIdentifier: "SidebarAccountSwitchAccountButton"
            ) {
                Task { await accountFlow?.switchAccount() }
            }
            accountMenuItem(
                title: String(localized: "settings.account.signOut", defaultValue: "Sign Out"),
                systemImage: "rectangle.portrait.and.arrow.right",
                accessibilityIdentifier: "SidebarAccountSignOutButton"
            ) {
                Task { await accountFlow?.signOut() }
            }
        } else {
            Button {
                accountFlow?.startSignIn()
            } label: {
                Label(signInTitle, systemImage: "person.crop.circle.badge.plus")
            }
            .accessibilityIdentifier("SidebarAccountSignInButton")
            if let offer = accountFlow?.upgradeOffer {
                accountMenuItem(
                    title: ProUpgradePresenter.upgradeMenuTitle(for: offer),
                    systemImage: "sparkles",
                    accessibilityIdentifier: "SidebarAccountUpgradeButton"
                ) {
                    accountFlow?.openProUpgrade(source: .sidebarAccountMenu)
                }
            }
        }
    }

    @ViewBuilder
    private var settingsMenuItem: some View {
        let shortcut = KeyboardShortcutSettings.shortcut(for: .openSettings)
        if let key = shortcut.keyEquivalent {
            Button {
                AppDelegate.shared?.openPreferencesWindow(
                    debugSource: "sidebar.account.settings",
                    navigationTarget: .account
                )
            } label: {
                Label(String(localized: "menu.app.settings", defaultValue: "Settings…"), systemImage: "gearshape")
            }
            .keyboardShortcut(key, modifiers: shortcut.eventModifiers)
            .accessibilityIdentifier("SidebarAccountSettingsButton")
        } else {
            Button {
                AppDelegate.shared?.openPreferencesWindow(
                    debugSource: "sidebar.account.settings",
                    navigationTarget: .account
                )
            } label: {
                Label(String(localized: "menu.app.settings", defaultValue: "Settings…"), systemImage: "gearshape")
            }
            .accessibilityIdentifier("SidebarAccountSettingsButton")
        }
    }

    private func accountMenuItem(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
