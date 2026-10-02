.pragma library

// Mirrors ~/.config/hypr/utils/functions.lua's default_config() - the built-in mapping of which
// apps each special-workspace keybind (SUPER+D, SUPER+M, ...) opens. That Lua table isn't in the
// flat "kbName = value" shape keybinds.js already parses (each app is its own nested table with
// a match array, a command array and flags), so it's kept here as plain data instead of parsed
// from the Lua source. If functions.lua's default_config() ever changes, mirror the change here
// too - there is nothing that checks the two agree.
function defaults() {
    return {
        communication: {
            discord: {
                enable: true,
                match: [{
                        class: "vesktop"
                    }],
                command: ["vesktop"],
                move: true
            },
            whatsapp: {
                enable: true,
                match: [{
                        class: "whatsapp"
                    }],
                move: true
            }
        },
        music: {
            spotify: {
                enable: true,
                match: [{
                        class: "Spotify"
                    }, {
                        initial_title: "Spotify"
                    }, {
                        initial_title: "Spotify Free"
                    }],
                command: ["spicetify", "watch", "-s"],
                move: true
            },
            feishin: {
                enable: true,
                match: [{
                        class: "feishin"
                    }],
                move: true
            }
        },
        sysmon: {
            btop: {
                enable: true,
                match: [{
                        class: "btop",
                        title: "btop",
                        workspace: {
                            name: "special:sysmon"
                        }
                    }],
                command: ["foot", "-a", "btop", "-T", "btop", "fish", "-C", "exec btop"]
            }
        },
        todo: {
            todoist: {
                enable: true,
                match: [{
                        class: "todoist"
                    }],
                command: ["todoist"],
                move: true
            }
        }
    };
}

function clone(v) {
    return JSON.parse(JSON.stringify(v));
}

// The effective config: defaults with the user's cli.json toggles merged in field by field,
// exactly like functions.lua's own merge() - a user entry overrides only the fields it sets,
// and can add a whole new app or category that was never in the defaults at all
function merged(userToggles) {
    const config = clone(defaults());
    for (const category of Object.keys(userToggles ?? {})) {
        config[category] = config[category] ?? {};
        for (const appName of Object.keys(userToggles[category])) {
            config[category][appName] = Object.assign({}, config[category][appName] ?? {}, userToggles[category][appName]);
        }
    }
    return config;
}

// Whether an app's match is the plain single "window class" case the settings page can edit
// directly, rather than a multi-rule or multi-field one (Spotify's three alternatives, btop's
// workspace-scoped rule) that only cli.json's own text can express
function isSimpleMatch(match) {
    return Array.isArray(match) && match.length === 1 && Object.keys(match[0]).length === 1 && typeof match[0].class === "string";
}

function classOf(match) {
    return isSimpleMatch(match) ? match[0].class : "";
}

// A command's argv array as one line the way someone would type it, and back. Only quotes an
// argument when it actually needs it (contains whitespace or a quote); no escape handling
// beyond that, since these are short, plain launch commands, not arbitrary shell scripts.
function splitShellWords(line) {
    const words = [];
    let i = 0;
    while (i < line.length) {
        while (i < line.length && /\s/.test(line[i]))
            i++;
        if (i >= line.length)
            break;

        let word = "";
        while (i < line.length && !/\s/.test(line[i])) {
            const c = line[i];
            if (c === "\"" || c === "'") {
                const quote = c;
                i++;
                while (i < line.length && line[i] !== quote) {
                    word += line[i];
                    i++;
                }
                i++; // the closing quote
            } else {
                word += c;
                i++;
            }
        }
        words.push(word);
    }
    return words;
}

function joinShellWords(words) {
    return (words ?? []).map(w => /\s|"/.test(w) ? `"${w.replace(/"/g, "\\\"")}"` : w).join(" ");
}
