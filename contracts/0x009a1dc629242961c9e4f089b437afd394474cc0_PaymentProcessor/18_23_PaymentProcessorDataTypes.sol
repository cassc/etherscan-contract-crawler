// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum TokenProtocols { ERC721, ERC1155 }

/**
 * @dev The `v`, `r`, and `s` components of an ECDSA signature.  For more information
 *      [refer to this article](https://medium.com/mycrypto/the-magic-of-digital-signatures-on-ethereum-98fe184dc9c7).
 */
struct SignatureECDSA {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @dev This struct is used as input to `buySingleListing` and `buyBatchOfListings` calls after an exchange matches
 * @dev a buyer and seller.
 *
 * @dev **sellerAcceptedOffer**: Denotes that the transaction was initiated by the seller account by accepting an offer.
 * @dev When true, ETH/native payments are not accepted, and only ERC-20 payment methods can be used.
 * @dev **collectionLevelOffer**: Denotes that the offer that was accepted was at the collection level.  When `true`,
 * @dev the Buyer should be prompted to sign the the collection offer approval stucture.  When false, the Buyer should
 * @dev prompted to sign the offer approval structure.
 * @dev **protocol**: 0 for ERC-721 or 1 for ERC-1155.  See `TokenProtocols`.
 * @dev **paymentCoin**: `address(0)` denotes native currency sale.  Otherwise ERC-20 payment coin address.
 * @dev **tokenAddress**: The smart contract address of the ERC-721 or ERC-1155 token being sold.
 * @dev **seller**: The seller/current owner of the token.
 * @dev **privateBuyer**: `address(0)` denotes a listing available to any buyer.  Otherwise, this denotes the privately
 * @dev designated buyer.
 * @dev **buyer**: The buyer/new owner of the token.
 * @dev **delegatedPurchaser**: Allows a buyer to delegate an address to buy a token on their behalf.  This would allow
 * @dev a warm burner wallet to purchase tokens and allow them to be received in a cold wallet, for example.
 * @dev **marketplace**: The address designated to receive marketplace fees, if applicable.
 * @dev **marketplaceFeeNumerator**: Marketplace fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev **maxRoyaltyFeeNumerator**: Maximum approved royalty fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev Marketplaces are responsible to query EIP-2981 royalty info from the NFT contract when presenting this
 * @dev for signature.
 * @dev **listingNonce**: The nonce the seller signed in the listing.
 * @dev **offerNonce**: The nonce the buyer signed in the offer.
 * @dev **listingMinPrice**: The minimum price the seller signed off on, in wei.  Buyer can buy above, 
 * @dev but not below the seller-approved minimum price.
 * @dev **offerPrice**: The sale price of the matched order, in wei.  Buyer signs off on the final offer price.
 * @dev **listingExpiration**: The timestamp at which the listing expires.
 * @dev **offerExpiration**: The timestamp at which the offer expires.
 * @dev **tokenId**: The id of the token being sold.  For ERC-721 tokens, this is the specific NFT token id.  
 * @dev For ERC-1155 tokens, this denotes the token type id.
 * @dev **amount**: The number of tokens being sold.  For ERC-721 tokens, this must always be `1`.
 * @dev For ERC-1155 tokens where balances are transferred, this must be greater than or equal to `1`.
 */
struct MatchedOrder {
    bool sellerAcceptedOffer;
    bool collectionLevelOffer;
    TokenProtocols protocol;
    address paymentCoin;
    address tokenAddress;
    address seller;
    address privateBuyer;
    address buyer;
    address delegatedPurchaser;
    address marketplace;
    uint256 marketplaceFeeNumerator;
    uint256 maxRoyaltyFeeNumerator;
    uint256 listingNonce;
    uint256 offerNonce;
    uint256 listingMinPrice;
    uint256 offerPrice;
    uint256 listingExpiration;
    uint256 offerExpiration;
    uint256 tokenId;
    uint256 amount;
}

/**
 * @dev This struct is used as input to `buyBundledListing` calls after an exchange matches a buyer and seller.
 * @dev Wraps `MatchedOrderBundleBase` and adds seller, listing nonce and listing expiration.
 *
 * @dev **bundleBase**: Includes all fields from `MatchedOrderBundleBase`.
 * @dev **seller**: The seller/current owner of all the tokens in a bundled listing.
 * @dev **listingNonce**: The nonce the seller signed in the listing. Only one nonce is required approving the sale
 * @dev of multiple tokens from one collection.
 * @dev **listingExpiration**: The timestamp at which the listing expires.
 */
struct MatchedOrderBundleExtended {
    MatchedOrderBundleBase bundleBase; 
    address seller;
    uint256 listingNonce;
    uint256 listingExpiration;
}

/**
 * @dev This struct is used as input to `sweepCollection` calls after an exchange matches multiple individual listings
 * @dev with a single buyer.
 *
 * @dev **protocol**: 0 for ERC-721 or 1 for ERC-1155.  See `TokenProtocols`.
 * @dev **paymentCoin**: `address(0)` denotes native currency sale.  Otherwise ERC-20 payment coin address.
 * @dev **tokenAddress**: The smart contract address of the ERC-721 or ERC-1155 token being sold.
 * @dev **privateBuyer**: `address(0)` denotes a listing available to any buyer.  Otherwise, this denotes the privately
 * @dev designated buyer.
 * @dev **buyer**: The buyer/new owner of the token.
 * @dev **delegatedPurchaser**: Allows a buyer to delegate an address to buy a token on their behalf.  This would allow
 * @dev a warm burner wallet to purchase tokens and allow them to be received in a cold wallet, for example.
 * @dev **marketplace**: The address designated to receive marketplace fees, if applicable.
 * @dev **marketplaceFeeNumerator**: Marketplace fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev **offerNonce**: The nonce the buyer signed in the offer.  Only one nonce is required approving the purchase
 * @dev of multiple tokens from one collection.
 * @dev **offerPrice**: The sale price of the entire order, in wei.  Buyer signs off on the final offer price.
 * @dev **offerExpiration**: The timestamp at which the offer expires.
 */
struct MatchedOrderBundleBase {
    TokenProtocols protocol;
    address paymentCoin;
    address tokenAddress;
    address privateBuyer;
    address buyer;
    address delegatedPurchaser;
    address marketplace;
    uint256 marketplaceFeeNumerator;
    uint256 offerNonce;
    uint256 offerPrice;
    uint256 offerExpiration;
}

/**
 * @dev This struct is used as input to `sweepCollection` and `buyBundledListing` calls.
 * @dev These fields are required per individual item listed.
 *
 * @dev **tokenId**: The id of the token being sold.  For ERC-721 tokens, this is the specific NFT token id.  
 * @dev For ERC-1155 tokens, this denotes the token type id.
 * @dev **amount**: The number of tokens being sold.  For ERC-721 tokens, this must always be `1`.
 * @dev For ERC-1155 tokens where balances are transferred, this must be greater than or equal to `1`.
 * @dev **maxRoyaltyFeeNumerator**: Maximum approved royalty fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev Marketplaces are responsible to query EIP-2981 royalty info from the NFT contract when presenting this
 * @dev for signature.
 * @dev **itemPrice**: The exact price the seller signed off on for an individual item, in wei. 
 * @dev Purchase price for the item must be exactly the listing item price.
 * @dev **listingNonce**: The nonce the seller signed in the listing for an individual item.  This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 * @dev **listingExpiration**: The timestamp at which an individual listing expires. This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 * @dev **seller**: The seller/current owner of the token. This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 */
struct BundledItem {
    uint256 tokenId;
    uint256 amount;
    uint256 maxRoyaltyFeeNumerator;
    uint256 itemPrice;
    uint256 listingNonce;
    uint256 listingExpiration;
    address seller;
}

/**
 * @dev This struct is used to define the marketplace behavior and constraints, giving creators flexibility to define
 *      marketplace behavior(s).
 *
 * @dev **enforceExchangeWhitelist**: Requires `buy` calls from smart contracts to be whitelisted.
 * @dev **enforcePaymentMethodWhitelist**: Requires ERC-20 payment coins for `buy` calls to be whitelisted as an 
 * @dev approved payment method.
 * @dev **enforcePricingConstraints**: Allows the creator to specify exactly one approved payment method, a minimum
 * @dev floor price and a maximum ceiling price.  When true, this value supercedes `enforcePaymentMethodWhitelist`.
 * @dev **disablePrivateListings**: Disables private sales.
 * @dev **disableDelegatedPurchases**: Disables purchases by delegated accounts on behalf of buyers.
 * @dev **disableEIP1271Signatures**: Disables sales and purchases using multi-sig wallets that implement EIP-1271.
 * @dev Enforces that buyers and sellers are EOAs.
 * @dev **disableExchangeWhitelistEOABypass**: Has no effect when `enforceExchangeWhitelist` is false.
 * @dev When exchange whitelist is enforced, this disables calls from EOAs, effectively requiring purchases to be
 * @dev composed by whitelisted 3rd party exchange contracts.
 * @dev **pushPaymentGasLimit**: This is the amount of gas to forward when pushing native payments.
 * @dev At the time this contract was written, 2300 gas is the recommended amount, but should costs of EVM opcodes
 * @dev change in the future, this field can be used to increase or decrease the amount of forwarded gas.  Care should
 * @dev be taken to ensure not enough gas is forwarded to result in possible re-entrancy.
 * @dev **policyOwner**: The account that has access to modify a security policy or update the exchange whitelist
 * @dev or approved payment list for the security policy.
 */
struct SecurityPolicy {
    bool enforceExchangeWhitelist;
    bool enforcePaymentMethodWhitelist;
    bool enforcePricingConstraints;
    bool disablePrivateListings;
    bool disableDelegatedPurchases;
    bool disableEIP1271Signatures;
    bool disableExchangeWhitelistEOABypass;
    uint32 pushPaymentGasLimit;
    address policyOwner;
}

/**
 * @dev This struct is used to define pricing constraints for a collection or individual token.
 *
 * @dev **isEnabled**: When true, this indicates that pricing constraints are set for the collection or token.
 * @dev **isImmutable**: When true, this indicates that pricing constraints are immutable and cannot be changed.
 * @dev **floorPrice**: The minimum price for a token or collection.  This is only enforced when 
 * @dev `enforcePricingConstraints` is `true`.
 * @dev **ceilingPrice**: The maximum price for a token or collection.  This is only enforced when
 * @dev `enforcePricingConstraints` is `true`.
 */
struct PricingBounds {
    bool isEnabled;
    bool isImmutable;
    uint256 floorPrice;
    uint256 ceilingPrice;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct SplitProceeds {
    address royaltyRecipient;
    uint256 royaltyProceeds;
    uint256 marketplaceProceeds;
    uint256 sellerProceeds;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct Accumulator {
    uint256[] tokenIds;
    uint256[] amounts;
    uint256[] salePrices;
    uint256[] maxRoyaltyFeeNumerators;
    address[] sellers;
    uint256 sumListingPrices;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct AccumulatorHashes {
    bytes32 tokenIdsKeccakHash;
    bytes32 amountsKeccakHash;
    bytes32 maxRoyaltyFeeNumeratorsKeccakHash;
    bytes32 itemPricesKeccakHash;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct PayoutsAccumulator {
    address lastSeller;
    address lastMarketplace;
    address lastRoyaltyRecipient;
    uint256 accumulatedSellerProceeds;
    uint256 accumulatedMarketplaceProceeds;
    uint256 accumulatedRoyaltyProceeds;
}

/**
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct ComputeAndDistributeProceedsArgs {
    uint256 pushPaymentGasLimit;
    address purchaser;
    IERC20 paymentCoin;
    function(address,address,IERC20,uint256,uint256) funcPayout;
    function(address,address,address,uint256,uint256) returns (bool) funcDispenseToken;
}