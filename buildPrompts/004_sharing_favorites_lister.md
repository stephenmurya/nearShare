# Implementation of Sharing, Favorites, and Lister Profiles

## 1. Social & Engagement Features
- **Share Implementation**: 
  - Added `share_plus` dependency.
  - Implemented share button in `ProductDetailsPage` app bar.
  - Content includes product name, price, and a dummy deep link.
- **Favorites System**:
  - Created `FavoritesProvider` to manage favorite IDs globally.
  - Registered provider in `main.dart`.
  - Implemented toggle logic in `ProductDetailsPage` with visual feedback (Red heart vs Outline).
  - Persisted state via Provider (in-memory for this session).

## 2. Lister Profiles
- **Data Model**:
  - Updated `Product` model to include `postedBy`, `userRating`, and `userProfilePic`.
  - Updated `mock_db.json` with sample lister data.
- **Lister Card**:
  - Added below product title in `ProductDetailsPage`.
  - Displays user avatar, name, rating, and verification status.
  - Navigates to `ListerProfilePage` on tap.
- **Lister Profile Page**:
  - Created `ListerProfilePage` to display specific user's feed.
  - Features profile header with avatar and rating.
  - Includes search bar to filter *only* that user's items.
  - Reuses `ProductCard` grid layout.

## 3. User Profile (Saved Items)
- **Menu Update**:
  - Added "Saved Items" tile to the Profile Page in `main_scaffold.dart`.
  - Uses `Iconsax.heart` icon.
- **Saved Items Page**:
  - Created `SavedItemsPage`.
  - Filters global product list by favored IDs from `FavoritesProvider`.
  - Shows "No saved items" placeholder when empty.

## 4. Technical Details
- **Dependencies Added**: `share_plus`.
- **Icons**: Used `iconsax` standard icons as alternatives to `IconsaxPlus` which was not available.
- **Typography**: Maintained `Inter Tight` font usage via `GoogleFonts`.
- **Null Safety**: Handled nullable fields for legacy/new data compatibility.

## 5. Next Steps
- Implement persistent storage for favorites (e.g., SharedPreferences or Hive).
- Add actual deep linking for share URLs.
- Implement real backend for user profiles.
