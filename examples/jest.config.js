module.exports = {
  preset: '@react-native/jest-preset',
  rootDir: __dirname,
  roots: [__dirname],
  transform: {
    '^.+\\.(js|ts|tsx)$': [
      'babel-jest',
      { babelrc: false, configFile: false, presets: ['module:@react-native/babel-preset'] },
    ],
  },
};
