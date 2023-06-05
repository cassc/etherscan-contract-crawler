// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds are represented by merkle roots
///      Each collection address ie. tokens[i] will have a merkle root corrosponding it's valid tokenIds.
///      This is used to select particular tokenId in corrospoding collection. If roots[i]
///      has the value of bytes32(0), this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Swap Params type to be used as one of the input params
/// @param tokens Tokens provided in the parameters
/// @param tokenIds Token Ids provided in the parameters
/// @param proofs Merkle proofs provided in the parameters
struct SwapParams {
    address[] tokens;
    uint256[] tokenIds;
    bytes32[][] proofs;
}

/// @dev Fees struct to be used to signify fees to be paid by a party
/// @param token Address of erc20 tokens to be used for payment
/// @param amount amount of tokens to be paid respectively
/// @param to address to which the fee is paid
struct Fees {
    address token;
    uint256 amount;
    address to;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}