# API Documentation

## Firebase Authentication

### Sign In: AuthenticationManager.signIn(email:password:)
- Parameters: email (String), password (String)
- Returns: AuthDataResultModel (contains uid, email, photoURL)

### Create User: AuthenticationManager.createUser(email:password:)

- Parameters: email (String), password (String)
- Returns: AuthDataResultModel (contains uid, email, photoURL)

### Sign Out: AuthenticationManager.signOut()

- Throws if sign out fails

## ZenQuotes API

- Endpoint: [https://zenquotes.io/api/quotes](https://zenquotes.io/api/quotes)
Request Method: GET
- Response Format: JSON array of quote objects
- Each object contains: "q" (quote content), "a" (author)
- Integration: QuotesService.fetchQuotes() handles fetching and parsing
