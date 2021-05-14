const path = require('path');

module.exports = {
  entry: './theme/src/index.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, 'theme', 'static', 'dist'),
  },
  mode: 'production',

  module: {
    rules: [
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.png$/,
        use: [ 'file-loader' ]
      }
    ]
  }
};
