// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Swap Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to swap features of the platform.

interface ISwap {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SwapErrorCodes {
        NOT_MARKET,
        INTENDED_FOR_PEER_TO_PEER_TRADE,
        INVALID_ADDRESS,
        OPTION_DOES_NOT_EXIST,
        ITEM_EXPIRED
    }

    error SwapError(SwapErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when listing has cancelled.
    /// @param listing Listing assets, details and seller's info
    event ListingCancelled(Listing listing);

    /// @dev Emits when swap offer has cancelled.
    /// @param offer Offer information
    event SwapOfferCancelled(SwapOffer offer);

    /// @dev Emits when collection offer has cancelled.
    /// @param offer Offer information
    event CollectionSwapOfferCancelled(CollectionSwapOffer offer);

    /// @dev Emits when direct swap has happened.
    /// @param listing Listing assets, details and seller's info
    /// @param offeredAssets Assets offered by the buyer
    /// @param swapId Swap id
    /// @param user Address of the buyer
    event DirectSwapped(
        Listing listing,
        Assets offeredAssets,
        uint256 swapId,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by the user.
    /// @param offer Swap offer assets and details
    /// @param considerationItems Assets given by the user
    /// @param user Address of the user who accepted the offer
    event UnlistedSwapOfferAccepted(
        SwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by a listing owner.
    /// @param listing Listing assets info
    /// @param offer Swap offer info
    /// @param user Listing owner
    event ListedSwapOfferAccepted(
        Listing listing,
        SwapOffer offer,
        address indexed user
    );

    /// @dev Emits when collection swap offer has accepted by the seller.
    /// @param offer Collection offer assets and details
    /// @param considerationItems Assets given by the seller
    /// @param user Address of the buyer
    event CollectionSwapOfferAccepted(
        CollectionSwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when new storage registry address has set.
    /// @param oldStorageRegistry Previous market contract address
    /// @param newStorageRegistry New market contract address
    event StorageRegistrySet(
        address oldStorageRegistry,
        address newStorageRegistry
    );

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel listing.
    /// @param listing Listing parameters
    /// @param signature Signature of the listing parameters
    /// @param user Listing owner
    function cancelListing(
        Listing calldata listing,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel Swap offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel collection level offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelCollectionSwapOffer(
        CollectionSwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Direct swap of bundle of NFTs + FTs with other bundles.
    /// @param listing Listing assets and details
    /// @param signature Signature as a proof of listing
    /// @param swapId Index of swap option being used
    /// @param value Eth value sent in the function call
    /// @param royalty Buyer's royalty info
    function directSwap(
        Listing calldata listing,
        bytes memory signature,
        uint256 swapId,
        address user,
        SwapParams memory swapParams,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accpet unlisted direct swap offer.
    /// @dev User should see the swap offer and accpet that offer.
    /// @param offer Multi offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param consideration Consideration assets been provided by the user
    /// @param proof Merkle proof that the considerationItems is valid
    /// @param user Address of the user who accepted this offer
    /// @param royalty Seller's royalty info
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept listed direct swap offer.
    /// @dev Only listing owner should accept that offer.
    /// @param listing Listing assets and parameters
    /// @param listingSignature Signature as a proof of listing
    /// @param offer Offering assets and parameters
    /// @param offerSignature Signature as a proof of offer
    /// @param proof Mekrle proof that the listed assets are valid
    /// @param user Listing owner
    function acceptListedDirectSwapOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        SwapOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept collection offer.
    /// @dev Anyone who holds the consideration assets can accpet this offer.
    /// @param offer Collection offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param user Seller address
    /// @param value Eth value send in the function call
    /// @param royalty Seller's royalty info
    function acceptCollectionSwapOffer(
        CollectionSwapOffer memory offer,
        bytes memory signature,
        SwapParams memory swapParams,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Storage registry contract address.
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;
}