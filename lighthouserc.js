module.exports = {
  ci: {
    assert: {
      assertions: {
        'largest-contentful-paint': ['error', { maxNumericValue: 19000 }],
        'errors-in-console': ['error', { maxLength: 10 }],
      },
    },
    collect: {
      url: [
        'http://localhost:2999/catalog/99122304923506421', // A show page
      ],
      startServerCommand: 'bundle exec rails server -p 2999',
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
}
