// List of window classes NOT to move
const EXCLUDED_CLASSES = [
  "plasmashell",
  "krunner",
  "yakuake",
  "systemsettings",
  "org.freedesktop.impl.portal.desktop.kde",
  "brave-browser",
  "spotify spotify",
  "vesktop",
  "org.kde.spectacle",
  "obsidian",
  "thunderbird",
  "1password",
];

const PULL_TO_CURRENT_CLASSES = ["1password"];

function ensureGeneralDesktop() {
  let general = workspace.desktops.find(
    (d) => d.name.toLowerCase() === "general",
  );
  if (!general) {
    general = workspace.createDesktop("general");
  }
  return general;
}

workspace.windowAdded.connect(function (window) {
  const cls = (window.resourceClass || "").toLowerCase();
  const type = window.windowType;

  print("New window:", window.resourceClass);

  if (EXCLUDED_CLASSES.includes(cls)) {
    return;
  }

  if (type !== 0) {
    return;
  }

  let general = ensureGeneralDesktop();

  if (general) {
    window.desktops = [general];

    if ("currentVirtualDesktop" in workspace) {
      workspace.currentVirtualDesktop = general;
    } else {
      workspace.currentDesktop = general;
    }
  }
});

workspace.windowActivated.connect(function (window) {
  print("Window activated", window.resourceClass.toLowerCase());
  if (!window) return;

  const cls = (window.resourceClass || "").toLowerCase();

  if (PULL_TO_CURRENT_CLASSES.includes(cls)) {
    print("Activated window of class " + cls);
    if ("currentVirtualDesktop" in workspace) {
      const current = workspace.currentVirtualDesktop;
      if (!window.desktops.includes(current)) {
        window.desktops = [current];
        print(" → moved to current virtual desktop");
      }
    } else {
      const current = workspace.currentDesktop; // Plasma 5
      if (window.desktop !== current) {
        window.desktop = current;
        print(" → moved to current desktop");
      }
    }
  }
});
