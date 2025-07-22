---
applyTo: "lib/api.dart"
---

# Copilot Instructions: Generate Typed Dart API Client for Grain Social Endpoints

## Goal

Generate a Dart API client for the Grain social endpoints, using the lexicon
JSON files in `lexicons/social/grain` and its subfolders. Each endpoint should
have:

- Typed request and response models
- API methods with correct parameters and return types
- Documentation from the lexicon descriptions

## Instructions for Copilot

1. **For each lexicon JSON file:**
   - Parse the endpoint definition (`id`, `type`, `description`,
     `parameters`/`input`, `output`).
   - Generate a Dart class for request parameters/input.
   - Generate a Dart class for response/output.
   - Use the [freezed](https://pub.dev/packages/freezed) package to generate an
     immutable model for each response type.
   - Each model class should be created in a separate file in
     `models/procedures`.
   - Create a Dart method for the endpoint, with correct types and
     documentation.
   - Each API method should:
     - Accept an `apiUrl` parameter as a prefix for requests (e.g.,
       `$apiUrl/xrpc/${id}`).
     - Pass the API token in the `Authorization` header for all requests.
     - Use the endpoint URL format `/xrpc/${id}` (e.g.,
       `/xrpc/social.grain.actor.getProfile`).

2. **Type Mapping:**
   - JSON `string` → Dart `String`
   - JSON `object` → Dart class
   - JSON `array` → Dart `List<T>`
   - JSON `integer` → Dart `int`
   - JSON `boolean` → Dart `bool`
   - JSON `*/*` (binary) → Dart `Uint8List` or `List<int>`

3. **API Method Example:**
   ```dart
   /// Get detailed profile view of an actor.
   Future<ProfileViewDetailed> getProfile(String actor);

   /// Create a comment.
   Future<CommentResponse> createComment(CreateCommentRequest request);

   /// Create a follow relationship.
   Future<FollowResponse> createFollow(String subject);

   /// Create a photo.
   Future<PhotoResponse> createPhoto(Uint8List photoData);
   ```

4. **Documentation:**
   - Use the `description` field from the lexicon for method/class docs.

5. **Error Handling:**
   - Generate error classes/types for API errors.

6. **Authentication:**
   - Mark endpoints that require auth.

## Reference

Use all JSON files in `lexicons/social/grain` and subfolders. For each endpoint,
use the schema references for response types if available.

## Example Endpoints

### Get Actor Profile

- **ID:** `social.grain.actor.getProfile`
- **Type:** Query
- **Description:** Get detailed profile view of an actor. Does not require auth,
  but contains relevant metadata with auth.
- **Parameters:** `actor` (string, at-identifier)
- **Response:** JSON, schema: `social.grain.actor.defs#profileViewDetailed`
