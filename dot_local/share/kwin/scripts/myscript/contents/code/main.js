// List of window classes NOT to move
const EXCLUDED_CLASSES = [
  "plasmashell",
  "org.kde.plasmashell",
  "krunner",
  "yakuake",
  "systemsettings",
  "org.freedesktop.impl.portal.desktop.kde",
  "brave-browser",
  "spotify",
  "vesktop",
  "org.kde.spectacle",
  "obsidian",
  "md.obsidian.obsidian",
  "thunderbird",
  "1password",
  "com.onepassword.onepassword",
  "brave-cinhimbnkkaeohfgghhklpknlkffjgod-default",
];

const PULL_TO_CURRENT_CLASSES = ["1password", "com.onepassword.onepassword"];

function findGeneralDesktop() {
  return workspace.desktops.find((d) => d.name.toLowerCase() === "general");
}

function ensureGeneralDesktop() {
  let general = findGeneralDesktop();
  if (!general) {
    workspace.createDesktop(workspace.desktops.length, "general");
    general = findGeneralDesktop();
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

  const general = ensureGeneralDesktop();
  if (!general) {
    print("Could not find or create the general desktop");
    return;
  }

  window.desktops = [general];
  workspace.currentDesktop = general;
});

workspace.windowActivated.connect(function (window) {
  if (!window) return;

  const cls = (window.resourceClass || "").toLowerCase();
  print("Window activated", cls);

  if (PULL_TO_CURRENT_CLASSES.includes(cls)) {
    print("Activated window of class " + cls);
    const current = workspace.currentDesktop;
    if (!window.desktops.includes(current)) {
      window.desktops = [current];
      print(" → moved to current virtual desktop");
    }
  }
});
