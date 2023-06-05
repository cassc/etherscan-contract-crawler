// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Reserve Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to reservation swap features of the platform.

interface IReserve {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum ReserveErrorCodes {
        NOT_MARKET,
        TIME_OVERFLOW,
        NOT_POSITION_TOKEN_OWNER,
        NOT_TIME_TO_CLAIM,
        OPTION_DOES_NOT_EXIST,
        INVALID_POSITION_TOKEN,
        INTENDED_FOR_PEER_TO_PEER_TRADE,
        INVALID_USER,
        INVALID_RESERVATION_DURATION,
        INVALID_ADDRESS,
        AIRDROP_CONTRACT_NOT_WHITELISTED
    }

    error ReserveError(ReserveErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the offer has cancelled.
    /// @param offer Reservation offer info
    event ReserveOfferCancelled(ReserveOffer offer);

    /// @dev Emits when the collectoin offer has been cancelled
    /// @param offer Collection reserve offer info
    event CollectionReserveOfferCancelled(CollectionReserveOffer offer);

    /// @dev Emits when the buyer has deposited reserve assets.
    /// @param listing Listing info
    /// @param reservation Reservation info
    /// @param reserveId Reserve id
    /// @param positionTokenId Token if of the position token
    /// @param user Buyer address
    event ReserveDeposited(
        Listing listing,
        Reservation reservation,
        uint256 reserveId,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the seller has accepted listed reservation offer.
    /// @param reservation Reservation info
    /// @param positionTokenId Token if of the position token
    /// @param user Listing owner
    event ListedReserveOfferAccepted(
        Listing listing,
        ReserveOffer offer,
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the offer has been accepted
    /// @param offer Reservation offer accepted
    /// @param reservation Reservation info
    /// @param considerationItems Assets given by the user
    /// @param positionTokenId Token id of the position token
    /// @param user Asset owner
    event UnlistedReserveOfferAccepted(
        ReserveOffer offer,
        Reservation reservation,
        Assets considerationItems,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the collection offer has been accepted
    /// @param offer Reservation collection offer that is accepted
    /// @param considerationItem Assets given by the user
    /// @param reservation Reservation info
    /// @param positionTokenId TokenId of the position token for this trade
    /// @param user Assets owner
    event CollectionReserveOfferAccepted(
        CollectionReserveOffer offer,
        Assets considerationItem,
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the buyer has paid remaining reserve assets.
    /// @param reservation Reservation info
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    event RemainsPaid(
        Reservation reservation,
        uint256 positionTokenId,
        address indexed user
    );

    /// @dev Emits when the seller has claimed locked assets.
    /// @param reservation Reservation info
    /// @param positionTokenId Position token id
    /// @param user Seller address
    event Claimed(
        Reservation reservation,
        uint256 positionTokenId,
        address user
    );

    /// @dev Emits when minimum reservation duration is updated
    /// @param oldMinimumReservationDuration Previous minimum reservation duration
    /// @param newMinimumReservationDuration New minimum reservation duration
    event MinimumReservationDurationSet(
        uint256 oldMinimumReservationDuration,
        uint256 newMinimumReservationDuration
    );

    /// @dev Emits when storege registry address is set
    /// @param oldStorageRegistryAddress Previous storage registry address
    /// @param newStorageRegistryAddress New storage registry address
    event StorageRegistrySet(
        address oldStorageRegistryAddress,
        address newStorageRegistryAddress
    );

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel reserve offer.
    /// @param offer Reserve offer info
    /// @param offerSignature Signature of the offer info
    /// @param user Offer owner
    function cancelReserveOffer(
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        address user
    ) external;

    /// @dev Cancel collection reservation offer
    /// @param offer Collection reserve offer info
    /// @param signature Signature of the offer
    /// @param user Offer owner
    function cancelCollectionReserveOffer(
        CollectionReserveOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Reserve swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Deposit reservation assets.
    /// @param listing Listing info
    /// @param listingSignature Signature of listing info
    /// @param reserveId Listing reserve id
    /// @param user Buyer address
    /// @param value Deposit Eth amount of buyer
    /// @param sellerFees Fee to be paid by the seller
    /// @param buyerFees Fee to be paid by the buyer
    function reserveDeposit(
        Listing calldata listing,
        bytes memory listingSignature,
        uint256 reserveId,
        address user,
        uint256 value,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept reservation offer using a listing.
    /// @param listing Listing info
    /// @param listingSignature Signature of listing info
    /// @param offer Reservation offer info
    /// @param offerSignature Signature of offer info
    /// @param user Listing owner address
    /// @param sellerFees Fee to be paid by the seller
    /// @param buyerFees Fee to be paid by the buyer
    function acceptListedReserveOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept reservation offer without listing
    /// @param offer Reservation offer info
    /// @param offerSignature Signature of offer info
    /// @param consideration Consideration assets provided for the offer
    /// @param proof merkle proof of the consideration assets
    /// @param user Listing owner address
    /// @param value Eth value sent along with the function call
    /// @param royalty Royalty offered by the user
    /// @param sellerFees Fee to be paid by the seller
    /// @param buyerFees Fee to be paid by the buyer
    function acceptUnlistedReserveOffer(
        ReserveOffer calldata offer,
        bytes memory offerSignature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Accept resevation collection offer
    /// @param offer collection reserve offer
    /// @param signature Signature of the offer
    /// @param swapParams details token, tokenId and merkle proofs provided
    /// @param user Address which accepted the offer
    /// @param value Eth value sent along
    /// @param royalty Seller's royalty info
    /// @param sellerFees Fee to be paid by the seller
    /// @param buyerFees Fee to be paid by the buyer
    function acceptCollectionReserveOffer(
        CollectionReserveOffer calldata offer,
        bytes memory signature,
        SwapParams memory swapParams,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata sellerFees,
        Fees calldata buyerFees
    ) external;

    /// @dev Pay remaining amount.
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    /// @param value Remaining Eth amount of buyer
    /// @param royalty Buyer's royalty info
    /// @param buyerFees Fee to be paid by the buyer
    function payRemains(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address user,
        uint256 value,
        Royalty calldata royalty,
        Fees calldata buyerFees
    ) external;

    /// @dev Claim the seller's locked assets from the vault when the time is over.
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param user Buyer address
    function claimDefaulted(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address user
    ) external;

    /// @dev Claim ongoing airdrops using the reserved assets
    /// @param reservation Reservation details
    /// @param positionTokenId Position token id
    /// @param airdropContract Address of the air drop contract
    /// @param data Data to pass in the call, ie. ABI encoded function signature with params
    /// @param user function caller's address
    function claimAirdrop(
        Reservation calldata reservation,
        uint256 positionTokenId,
        address airdropContract,
        bytes calldata data,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set minimum reservation duration
    /// @param minimumReservationDuration Minimum reservation duration
    function setMinimumReservationDuration(uint256 minimumReservationDuration)
        external;

    /// @dev Set Storage registry contract address.
    /// @param _storageRegistryAddress storage registry contract address
    function setStorageRegistry(address _storageRegistryAddress) external;
}