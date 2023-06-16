// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PaymentProcessorDataTypes.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IPaymentProcessor
 * @author Limit Break, Inc.
 * @notice Interface definition for payment processor contracts.
 */
interface IPaymentProcessor is IERC165 {

    /// @notice Emitted when a bundle of ERC-721 tokens is successfully purchased using `buyBundledListing`
    event BuyBundledListingERC721(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        bool[] unsuccessfulFills,
        uint256[] tokenIds,
        uint256[] salePrices);

    /// @notice Emitted when a bundle of ERC-1155 tokens is successfully purchased using `buyBundledListing`
    event BuyBundledListingERC1155(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        bool[] unsuccessfulFills,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] salePrices);

    /// @notice Emitted for each token successfully purchased using either `buySingleLising` or `buyBatchOfListings`
    event BuySingleListing(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 salePrice);

    /// @notice Emitted when a security policy is either created or modified
    event CreatedOrUpdatedSecurityPolicy(
        uint256 indexed securityPolicyId, 
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string policyName);

    /// @notice Emitted when an address is added to the exchange whitelist for a security policy
    event ExchangeAddedToWhitelist(uint256 indexed securityPolicyId, address indexed exchange);

    /// @notice Emitted when an address is removed from the exchange whitelist for a security policy
    event ExchangeRemovedFromWhitelist(uint256 indexed securityPolicyId, address indexed exchange);

    /// @notice Emitted when a user revokes all of their existing listings or offers that share the master nonce.
    event MasterNonceInvalidated(uint256 indexed nonce, address indexed account);

    /// @notice Emitted when a user revokes a single listing or offer nonce for a specific marketplace.
    event NonceInvalidated(
        uint256 indexed nonce, 
        address indexed account, 
        address indexed marketplace, 
        bool wasCancellation);

    /// @notice Emitted when a coin is added to the approved coins mapping for a security policy
    event PaymentMethodAddedToWhitelist(uint256 indexed securityPolicyId, address indexed coin);

    /// @notice Emitted when a coin is removed from the approved coins mapping for a security policy
    event PaymentMethodRemovedFromWhitelist(uint256 indexed securityPolicyId, address indexed coin);

    /// @notice Emitted when the ownership of a security policy is transferred to a new account
    event SecurityPolicyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when a collection of ERC-721 tokens is successfully swept using `sweepCollection`
    event SweepCollectionERC721(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        bool[] unsuccessfulFills,
        address[] sellers,
        uint256[] tokenIds,
        uint256[] salePrices);

    /// @notice Emitted when a collection of ERC-1155 tokens is successfully swept using `sweepCollection`
    event SweepCollectionERC1155(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        bool[] unsuccessfulFills,
        address[] sellers,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] salePrices);

    /// @notice Emitted whenever the designated security policy id changes for a collection.
    event UpdatedCollectionSecurityPolicy(address indexed tokenAddress, uint256 indexed securityPolicyId);

    /// @notice Emitted whenever the supported ERC-20 payment is set for price-constrained collections.
    event UpdatedCollectionPaymentCoin(address indexed tokenAddress, address indexed paymentCoin);

    /// @notice Emitted whenever pricing bounds change at a collection level for price-constrained collections.
    event UpdatedCollectionLevelPricingBoundaries(
        address indexed tokenAddress, 
        uint256 floorPrice, 
        uint256 ceilingPrice);

    /// @notice Emitted whenever pricing bounds change at a token level for price-constrained collections.
    event UpdatedTokenLevelPricingBoundaries(
        address indexed tokenAddress, 
        uint256 indexed tokenId, 
        uint256 floorPrice, 
        uint256 ceilingPrice);
    
    function createSecurityPolicy(
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external returns (uint256);

    function updateSecurityPolicy(
        uint256 securityPolicyId,
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external;

    function transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) external;
    function renounceSecurityPolicyOwnership(uint256 securityPolicyId) external;
    function setCollectionSecurityPolicy(address tokenAddress, uint256 securityPolicyId) external;
    function setCollectionPaymentCoin(address tokenAddress, address coin) external;
    function setCollectionPricingBounds(address tokenAddress, PricingBounds calldata pricingBounds) external;

    function setTokenPricingBounds(
        address tokenAddress, 
        uint256[] calldata tokenIds, 
        PricingBounds[] calldata pricingBounds) external;

    function whitelistExchange(uint256 securityPolicyId, address account) external;
    function unwhitelistExchange(uint256 securityPolicyId, address account) external;
    function whitelistPaymentMethod(uint256 securityPolicyId, address coin) external;
    function unwhitelistPaymentMethod(uint256 securityPolicyId, address coin) external;
    function revokeMasterNonce() external;
    function revokeSingleNonce(address marketplace, uint256 nonce) external;

    function buySingleListing(
        MatchedOrder memory saleDetails, 
        SignatureECDSA memory signedListing, 
        SignatureECDSA memory signedOffer
    ) external payable;

    function buyBatchOfListings(
        MatchedOrder[] calldata saleDetailsArray,
        SignatureECDSA[] calldata signedListings,
        SignatureECDSA[] calldata signedOffers
    ) external payable;

    function buyBundledListing(
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] calldata bundleItems) external payable;

    function sweepCollection(
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleBase memory bundleDetails,
        BundledItem[] calldata bundleItems,
        SignatureECDSA[] calldata signedListings) external payable;

    function getDomainSeparator() external view returns (bytes32);
    function getSecurityPolicy(uint256 securityPolicyId) external view returns (SecurityPolicy memory);
    function isWhitelisted(uint256 securityPolicyId, address account) external view returns (bool);
    function isPaymentMethodApproved(uint256 securityPolicyId, address coin) external view returns (bool);
    function getTokenSecurityPolicyId(address collectionAddress) external view returns (uint256);
    function isCollectionPricingImmutable(address tokenAddress) external view returns (bool);
    function isTokenPricingImmutable(address tokenAddress, uint256 tokenId) external view returns (bool);
    function getFloorPrice(address tokenAddress, uint256 tokenId) external view returns (uint256);
    function getCeilingPrice(address tokenAddress, uint256 tokenId) external view returns (uint256);
}