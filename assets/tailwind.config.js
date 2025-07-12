// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/chess_web.ex",
    "../lib/chess_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      //let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let piecesDir = path.join(__dirname, "./pieces");
      let values = {}
      let colors = ["white","black"];

      colors.forEach((color) => {
        fs.readdirSync(path.join(piecesDir, color)).map(file => {
          let name = `${color}-${path.basename(file, ".svg")}`;
          values[name] = {name, fullPath: path.join(piecesDir, color, file)}
        })
      })
      matchComponents({
        "piece": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")

          return {
            "background-image": `url('data:image/svg+xml;base64,${Buffer.from(
              content,
            ).toString("base64")}')`,
            display: "inline-block",
            width: theme("spacing.5"),
            height: theme("spacing.5"),
            "background-size": "contain",
          };
        }
      }, {values})
    })
  ]
}
