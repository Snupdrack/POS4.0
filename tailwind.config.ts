import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

const config: Config = {
  darkMode: "class",
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        bebas: ['Bebas Neue', 'sans-serif'],
        nunito: ['Nunito', 'sans-serif'],
      },
      colors: {
        nito: {
          DEFAULT: '#E31E24',
          cream: '#FFF8F0',
          gold: '#F5A623',
          dark: '#111111',
        },
      },
    },
  },
  plugins: [tailwindcssAnimate],
};

export default config;
