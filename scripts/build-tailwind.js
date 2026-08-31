const fs = require('fs');
const postcss = require('postcss');
const tailwindcssPlugin = require('@tailwindcss/postcss');
const autoprefixer = require('autoprefixer');

const inputPath = './src/styles/tailwind.css';
const outputPath = './public_assets/css/tailwind.css';

(async () => {
  try {
    const input = fs.readFileSync(inputPath, 'utf8');
    const result = await postcss([tailwindcssPlugin(require('../tailwind.config.cjs')), autoprefixer]).process(input, {
      from: inputPath,
      to: outputPath,
      map: false,
    });
    fs.writeFileSync(outputPath, result.css);
    console.log('Built', outputPath);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();
