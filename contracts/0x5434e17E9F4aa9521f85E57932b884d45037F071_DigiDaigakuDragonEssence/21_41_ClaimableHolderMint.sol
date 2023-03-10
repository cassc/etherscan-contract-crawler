// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ClaimPeriodBase.sol";
import "./MintTokenBase.sol";
import "./SequentialMintBase.sol";
import "../access/InitializableOwnable.sol";
import "../../initializable/IRootCollectionInitializer.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CallerDoesNotOwnRootTokenId();
error CannotInitializeIneligibleTokensAfterClaimsOpen();
error CollectionAddressIsNotAnERC721Token();
error IneligibleTokensAlreadyInitialized();
error IneligibleTokenArrayMustBeInAscendingOrder();
error IneligibleTokensFinalized();
error IneligibleTokensHaveNotBeenFinalized();
error IneligibleTokenMustBeWithinMaxSupply();
error InputArrayLengthMismatch();
error InvalidRootCollectionAddress();
error InvalidRootCollectionTokenId();
error MaxSupplyOfRootTokenCannotBeZero();
error MustSpecifyAtLeastOneIneligibleToken();
error MustSpecifyAtLeastOneRootCollection();
error RootCollectionsAlreadyInitialized();
error RootCollectionsHaveNotBeenInitialized();
error TokenIdAlreadyClaimed();
error TokensPerClaimMustBeBetweenOneAndTen();
error MaxNumberOfRootCollectionsExceeded();
error BatchSizeMustBeGreaterThanZero();
error BatchSizeGreaterThanMaximum();

/**
 * @title ClaimableHolderMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with sequential role-based minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IRootCollectionInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract ClaimableHolderMint is InitializableOwnable, ClaimPeriodBase, MintTokenBase, SequentialMintBase, IRootCollectionInitializer {

    struct ClaimableRootCollection {
        /// @dev Indicates whether or not this is a root collection
        bool isRootCollection;

        /// @dev This is the root ERC-721 contract from which claims can be made
        IERC721 rootCollection;

        /// @dev Max supply of the root collection
        uint256 maxSupply;

        /// @dev Number of tokens each user should get per token id claim
        uint256 tokensPerClaim;

        /// @dev Bitmap that helps determine if a token was ever claimed previously
        uint256[] claimedTokenTracker;

        /// @dev Mapping from slot to ineligible token bitmap
        mapping(uint256 => uint256) ineligibleTokenBitmaps;
    }

    /// @dev The maximum amount of minted tokens from one batch submission.
    uint256 private constant MAX_MINTS_PER_TRANSACTION = 300;

    /// @dev The maximum amount of Root Collections permitted
    uint256 private constant MAX_ROOT_COLLECTIONS = 25;

    /// @dev True if root collections have been initialized, false otherwise.
    bool private initializedRootCollections;

    /// @dev True if ineligible token lists have been finalized, false otherwise.
    bool private finalizedIneligibleTokens;

    /// @dev Mapping from root collection address to claim details
    mapping (address => ClaimableRootCollection) private rootCollectionLookup;

    /// @dev Emitted when a holder claims a mint
    event ClaimMinted(address indexed rootCollection, uint256 indexed rootCollectionTokenId, uint256 startTokenId, uint256 endTokenId);

    /// @dev Emitted when a root collection is initialized
    event RootCollectionInitialized(address indexed rootCollection, uint256 maxSupply, uint256 tokensPerClaim);

    /// @dev Emitted when a set of ineligible token slots and bitmaps are set for a root collection
    event IneligibleTokensInitialized(address indexed rootCollectionAddress, uint256[] ineligibleTokenSlots, uint256[] ineligibleTokenBitmaps);

    /// @dev Initializes root collection parameters that determine how the claims will work.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Params are memory to allow for initialization within constructors.
    /// The sum of all root collections max supplies cannot exceed 256,000 tokens.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the root collection has already been initialized.
    /// Throws when the specified root collection is not an ERC721 token.
    /// Throws when the number of tokens per claim is not between 1 and 10.
    /// Throws when a provided ineligible token is greater than the max supply.
    function initializeRootCollections(address[] memory rootCollections_, uint256[] memory rootCollectionMaxSupplies_, uint256[] memory tokensPerClaimArray_) public override onlyOwner {
        if(initializedRootCollections) {
            revert RootCollectionsAlreadyInitialized();
        }

        uint256 rootCollectionsArrayLength = rootCollections_.length;

        _requireInputArrayLengthsMatch(rootCollectionsArrayLength, rootCollectionMaxSupplies_.length);
        _requireInputArrayLengthsMatch(rootCollectionsArrayLength, tokensPerClaimArray_.length);

        if(rootCollectionsArrayLength == 0) {
            revert MustSpecifyAtLeastOneRootCollection();
        }
        if(rootCollectionsArrayLength > MAX_ROOT_COLLECTIONS) {
            revert MaxNumberOfRootCollectionsExceeded();
        }

        for(uint256 i = 0; i < rootCollectionsArrayLength;) {
            address rootCollection_ = rootCollections_[i];
            uint256 rootCollectionMaxSupply_ = rootCollectionMaxSupplies_[i];
            uint256 tokensPerClaim_ = tokensPerClaimArray_[i];

            emit RootCollectionInitialized(address(rootCollection_), rootCollectionMaxSupply_, tokensPerClaim_);

            if(!IERC165(rootCollection_).supportsInterface(type(IERC721).interfaceId)) {
                revert CollectionAddressIsNotAnERC721Token();
            }

            if(tokensPerClaim_ == 0 || tokensPerClaim_ > 10) {
                revert TokensPerClaimMustBeBetweenOneAndTen();
            }

            if(rootCollectionMaxSupply_ == 0) {
                revert MaxSupplyOfRootTokenCannotBeZero();
            }

            rootCollectionLookup[rootCollection_].isRootCollection = true;
            rootCollectionLookup[rootCollection_].rootCollection = IERC721(rootCollection_);
            rootCollectionLookup[rootCollection_].maxSupply = rootCollectionMaxSupply_;
            rootCollectionLookup[rootCollection_].tokensPerClaim = tokensPerClaim_;

            unchecked {
                // Initialize memory to use for tracking token ids that have been minted
                // The bit corresponding to token id defaults to 1 when unminted,
                // and will be set to 0 upon mint.
                uint256 numberOfTokenTrackerSlots = _getNumberOfTokenTrackerSlots(rootCollectionMaxSupply_);
                for(uint256 j = 0; j < numberOfTokenTrackerSlots; ++j) {
                    rootCollectionLookup[rootCollection_].claimedTokenTracker.push(type(uint256).max);
                }
                ++i;
            }
        }

        _initializeNextTokenIdCounter();
        initializedRootCollections = true;
    }

    /// @notice Accepts a list of slot and bitmaps to mark tokens ineligible for claim for the provided root collection address
    /// @dev You can generate the inputs for `ineligibleTokenSlots` and `ineligibleTokenBitmaps` by using the helper function `getIneligibleTokensBitmap`
    /// @dev Params are memory to allow for initialization within constructors.
    ///
    /// Throws when the root collections have not been initialized.
    /// Throws when ineligible tokens have already been finalized.
    /// Throws if the ineligible token slots & bitmap array lengths do not match.
    /// Postconditions:
    /// ---------------
    /// The ineligible token bitmaps are set on the root collection details.
    function initializeIneligibleTokens(bool finalize, address rootCollectionAddress, uint256[] memory ineligibleTokenSlots, uint256[] memory ineligibleTokenBitmaps) external {
        if(!initializedRootCollections) {
            revert RootCollectionsHaveNotBeenInitialized();
        }
        if(finalizedIneligibleTokens) {
            revert IneligibleTokensFinalized();
        }

        if(ineligibleTokenSlots.length != ineligibleTokenBitmaps.length) {
            revert InputArrayLengthMismatch();
        }

        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);

        if(finalize) {
            finalizedIneligibleTokens = true;
        }

        unchecked {
            for (uint256 i = 0; i < ineligibleTokenSlots.length; ++i) {
                rootCollectionDetails.claimedTokenTracker[ineligibleTokenSlots[i]] = ~ineligibleTokenBitmaps[i];
                rootCollectionDetails.ineligibleTokenBitmaps[ineligibleTokenSlots[i]] = ineligibleTokenBitmaps[i];
            }
        }

        emit IneligibleTokensInitialized(rootCollectionAddress, ineligibleTokenSlots, ineligibleTokenBitmaps);
    }

    /// @notice Allows a user to claim/mint one or more tokens pegged to their ownership of a list of specified token ids
    ///
    /// Throws when an empty array of root collection token ids is provided.
    /// Throws when the amount of claimed tokens exceeds the max claimable amount.
    /// Throws when the claim period has not opened.
    /// Throws when the claim period has closed.
    /// Throws when the caller does not own the specified token id from the root collection.
    /// Throws when the root token id has already been claimed.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    /// Postconditions:
    /// ---------------
    /// The root collection and token ID combinations are marked as claimed in the root collection's claimed token tracker.
    /// `quantity` tokens are minted to the msg.sender, where `quantity` is the amount of tokens per claim * length of the rootCollectionTokenIds array.
    /// `quantity` ClaimMinted events have been emitted, where `quantity` is the amount of tokens per claim * length of the rootCollectionTokenIds array.
    function claimBatch(address rootCollectionAddress, uint256[] calldata rootCollectionTokenIds) external {
        _requireClaimsOpen();

        if (rootCollectionTokenIds.length == 0) {
            revert BatchSizeMustBeGreaterThanZero();
        }

        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);

        uint256 maxBatchSize = MAX_MINTS_PER_TRANSACTION / rootCollectionDetails.tokensPerClaim;

        if (rootCollectionTokenIds.length > maxBatchSize) {
            revert BatchSizeGreaterThanMaximum();
        }

        for(uint256 i = 0; i < rootCollectionTokenIds.length;) {
            _claim(rootCollectionDetails, rootCollectionTokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Processes a claim for a Root Collection + Root Collection Token ID Combination
    ///
    /// Throws when the caller does not own the specified token id from the root collection.
    /// Throws when the root token id has already been claimed.
    /// Throws if safe mint receiver is not an EOA or a contract that can receive tokens.
    /// Postconditions:
    /// ---------------
    /// The root collection and tokenID combination are marked as claimed in the root collection's claimed token tracker.
    /// `quantity` tokens are minted to the msg.sender, where `quantity` is the amount of tokens per claim.
    /// The nextTokenId counter is advanced by the `quantity` of tokens minted.
    /// `quantity` ClaimMinted events have been emitted, where `quantity` is the amount of tokens per claim.
    function _claim(ClaimableRootCollection storage rootCollectionDetails, uint256 rootCollectionTokenId) internal {
        if(rootCollectionDetails.rootCollection.ownerOf(rootCollectionTokenId) != _msgSender()) {
            revert CallerDoesNotOwnRootTokenId();
        }

        (bool claimed, uint256 slot, uint256 offset, uint256 slotValue) = _isClaimed(rootCollectionDetails, rootCollectionTokenId);
        if(claimed) {
            revert TokenIdAlreadyClaimed();
        }

        uint256 claimedTokenId = getNextTokenId();
        uint256 tokensPerClaim_ = rootCollectionDetails.tokensPerClaim;
        emit ClaimMinted(address(rootCollectionDetails.rootCollection), rootCollectionTokenId, claimedTokenId, claimedTokenId + tokensPerClaim_ - 1);

        rootCollectionDetails.claimedTokenTracker[slot] = slotValue & ~(uint256(1) << offset);

        unchecked {
            _advanceNextTokenIdCounter(tokensPerClaim_);

            for(uint256 i = 0; i < tokensPerClaim_; ++i) {
                _mintToken(_msgSender(), claimedTokenId + i);
            }
        }
    }

    /// @notice Helper function to return slots and formatted bitmap given an array of ineligible tokens
    /// @dev Do not use this in any contract calls as there is unoptimized gas usage.  You should use this to
    /// @dev generate the input for `initializeIneligibleTokens`
    /// @dev `ineligibleTokenIds` must be a sorted list of token IDs to return the bitmap and slot arrays
    function computeIneligibleTokensBitmap(uint256[] calldata ineligibleTokenIds) external pure returns (uint256[] memory, uint256[] memory) {
        if (ineligibleTokenIds.length == 0) {
            revert MustSpecifyAtLeastOneIneligibleToken();
        }

        uint256 lastTokenId = ineligibleTokenIds[ineligibleTokenIds.length - 1];
        uint256 lastSeenId = 0;

        uint256 numberOfTokenTrackerSlots = _getNumberOfTokenTrackerSlots(lastTokenId);
        uint256[] memory tempBitmapArray = new uint256[](numberOfTokenTrackerSlots);

        unchecked {
            // Modify bitmaps for each token
            // Note: an individual slot may be modified more than once
            for (uint256 i = 0; i < ineligibleTokenIds.length; ++i) {
                uint256 tokenId = ineligibleTokenIds[i];

                if(i > 0 && tokenId <= lastSeenId) {
                    revert IneligibleTokenArrayMustBeInAscendingOrder();
                }

                lastSeenId = tokenId;

                uint256 slot = tokenId / 256;
                uint256 offset = tokenId % 256;

                uint256 bitmap = tempBitmapArray[slot];
                tempBitmapArray[slot] = bitmap | (uint256(1) << offset);
            }

            uint256 count;

            // Iterate over all slots to identify modified values
            for (uint256 i = 0; i < numberOfTokenTrackerSlots; ++i) {
                if(tempBitmapArray[i] > 0) {
                    ++count;
                }
            }

            // Initialize arrays with values = count of modified slots
            uint256[] memory bitmapArray = new uint256[](count);
            uint256[] memory slotArray = new uint256[](count);

            uint256 index;

            // Populate return values
            for (uint256 i = 0; i < numberOfTokenTrackerSlots; ++i) {
                if(tempBitmapArray[i] > 0) {
                    bitmapArray[index] = tempBitmapArray[i];
                    slotArray[index] = i;
                    ++index;
                }
            }

            return (slotArray, bitmapArray);
        }
    }

    /// @notice Returns the amount of tokens minted per claim for the provided root collection
    function getTokensPerClaim(address rootCollectionAddress) public view returns (uint256) {
        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);

        return rootCollectionDetails.tokensPerClaim;
    }

    /// @notice Returns true if the specified token id is eligible for claiming, false otherwise
    function isEligible(address rootCollectionAddress, uint256 tokenId) public view returns (bool) {
        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);
        if(tokenId > rootCollectionDetails.maxSupply) {
            revert InvalidRootCollectionTokenId();
        }
        uint256 slot = tokenId / 256;
        uint256 offset = tokenId % 256;
        uint256 slotValue = rootCollectionDetails.ineligibleTokenBitmaps[slot];
        bool ineligible = ((slotValue >> offset) & uint256(1)) == 1;
        return !ineligible;
    }

    /// @notice Returns true if the specified token id has been claimed
    function isClaimed(address rootCollectionAddress, uint256 tokenId) public view returns (bool) {
        ClaimableRootCollection storage rootCollectionDetails = _getRootCollectionDetailsSafe(rootCollectionAddress);
        
        if(tokenId > rootCollectionDetails.maxSupply) {
            revert InvalidRootCollectionTokenId();
        }

        (bool claimed,,,) = _isClaimed(rootCollectionDetails, tokenId);
        return claimed;
    }

    /// @dev Returns whether or not the specified token id has been claimed/minted as well as the bitmap slot/offset/slot value of the token id
    function _isClaimed(ClaimableRootCollection storage rootCollectionDetails, uint256 tokenId) internal view returns (bool claimed, uint256 slot, uint256 offset, uint256 slotValue) {
        unchecked {
            slot = tokenId / 256;
            offset = tokenId % 256;
            slotValue = rootCollectionDetails.claimedTokenTracker[slot];
            claimed = ((slotValue >> offset) & uint256(1)) == 0;
        }
        
        return (claimed, slot, offset, slotValue);
    }

    /// @dev Determines number of slots required to track minted tokens across the max supply
    function _getNumberOfTokenTrackerSlots(uint256 maxSupply_) internal pure returns (uint256 tokenTrackerSlotsRequired) {
        unchecked {
            // Add 1 because we are starting valid token id range at 1 instead of 0
            uint256 maxSupplyPlusOne = 1 + maxSupply_;
            tokenTrackerSlotsRequired = maxSupplyPlusOne / 256;
            if(maxSupplyPlusOne % 256 > 0) {
                ++tokenTrackerSlotsRequired;
            }
        }

        return tokenTrackerSlotsRequired;
    }

    /// @dev Validates that the length of two input arrays matched.
    /// Throws if the array lengths are mismatched.
    function _requireInputArrayLengthsMatch(uint256 inputArray1Length, uint256 inputArray2Length) internal pure {
        if(inputArray1Length != inputArray2Length) {
            revert InputArrayLengthMismatch();
        }
    }

    /// @dev Safely gets a storage pointer to the details of a root collection.  Performs validation and throws if the value is not present in the mapping, preventing
    /// the possibility of overwriting an unexpected storage slot.
    ///
    /// Throws when the specified root collection address has not been explicitly set as a key in the mapping.
    function _getRootCollectionDetailsSafe(address rootCollectionAddress) private view returns (ClaimableRootCollection storage) {
        ClaimableRootCollection storage rootCollectionDetails = rootCollectionLookup[rootCollectionAddress];

        if(!rootCollectionDetails.isRootCollection) {
            revert InvalidRootCollectionAddress();
        }

        return rootCollectionDetails;
    }

    function _onClaimPeriodOpening() internal virtual override {
        if(!initializedRootCollections) {
            revert RootCollectionsHaveNotBeenInitialized();
        }

        if(!finalizedIneligibleTokens) {
            revert IneligibleTokensHaveNotBeenFinalized();
        }
    }
}