// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IOwnable.sol";
import "./IPaymentProcessor.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title  PaymentProcessor
 * @author Limit Break, Inc.
 * @notice The world's first ERC721-C compatible marketplace contract!  
 * @notice Use ERC721-C to whitelist this contract or other marketplace contracts that process royalties entirely 
 *         on-chain manner to make them 100% enforceable and fully programmable! 
 *
 * @notice <h4>Features</h4>
 *
 * @notice <ul>
 *            <li>Creator Defined Security Profiles</li>
 *            <ul>
 *             <li>Exchange Whitelist On/Off</li>
 *             <li>Payment Method Whitelist On/Off</li>
 *             <li>Pricing Constraints On/Off</li>
 *             <li>Private Sales On/Off</li>
 *             <li>Delegate Purchase Wallets On/Off</li>
 *             <li>Smart Contract Buyers/Sellers On/Off</li>
 *             <li>Exchange Whitelist Bypass for EOAs On/Off</li>
 *            </ul>
 *           <li>Enforceable/Programmable Fees</li>
 *           <ul>
 *             <li>Built-in EIP-2981 Royalty Enforcement</li>
 *             <li>Built-in Marketplace Fee Enforcement</li>
 *           </ul>
 *           <li>Multi-Standard Support</li>
 *           <ul>
 *             <li>ERC721-C</li>
 *             <li>ERC1155-C</li>
 *             <li>ERC721 + EIP-2981</li>
 *             <li>ERC1155 + EIP-2981</li>
 *           </ul>
 *           <li>Payments</li>
 *           <ul>
 *             <li>Native Currency (ETH or Equivalent)</li>
 *             <li>ERC-20 Coin Payments</li>
 *           </ul>
 *           <li>A Multitude of Supported Sale Types</li>
 *           <ul>
 *             <li>Buy Single Listing</li>
 *             <ul>
 *               <li>Collection-Level Offers</li>
 *               <li>Item-Specific Offers</li>
 *             </ul>
 *             <li>Buy Batch of Listings (Shopping Cart)</li>
 *             <li>Buy Bundled Listing (From One Collection)</li>
 *             <li>Sweep Listings (From One Collection)</li>
 *             <li>Partial Order Fills (When ERC-20 Payment Method Is Used)</li>
 *           </ul>
 *         </ul>
 *
 * @notice <h4>Security Considerations for Users</h4>
 *
 * @notice Virtually all on-chain marketplace contracts have the potential to be front-run.
 *         When purchasing high-value items, whether individually or in a batch/bundle it is highly
 *         recommended to execute transactions using Flashbots RPC Relay/private mempool to avoid
 *         sniper bots.  Partial fills are available for batched purchases, bundled listing purchases,
 *         and collection sweeps when the method of payment is an ERC-20 token, but not for purchases
 *         using native currency.  It is preferable to use wrapped ETH (or equivalent) when buying
 *         multiple tokens and it is highly advisable to use Flashbots whenever possible.  [Read the
 *         quickstart guide for more information](https://docs.flashbots.net/flashbots-protect/rpc/quick-start).
 */
contract PaymentProcessor is ERC165, EIP712, Ownable, Pausable, IPaymentProcessor {

    error PaymentProcessor__AddressCannotBeZero();
    error PaymentProcessor__AmountForERC721SalesMustEqualOne();
    error PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
    error PaymentProcessor__BundledOfferPriceMustEqualSumOfAllListingPrices();
    error PaymentProcessor__BuyerDidNotAuthorizePurchase();
    error PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
    error PaymentProcessor__CallerDoesNotOwnSecurityPolicy();
    error PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
    error PaymentProcessor__CallerIsNotWhitelistedMarketplace();
    error PaymentProcessor__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
    error PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
    error PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
    error PaymentProcessor__CoinDoesNotImplementDecimalsAndLikelyIsNotAnERC20Token();
    error PaymentProcessor__CoinIsApproved();
    error PaymentProcessor__CoinIsNotApproved();
    error PaymentProcessor__CollectionLevelOrItemLevelOffersCanOnlyBeMadeUsingERC20PaymentMethods();
    error PaymentProcessor__DispensingTokenWasUnsuccessful();
    error PaymentProcessor__EIP1271SignaturesAreDisabled();
    error PaymentProcessor__EIP1271SignatureInvalid();
    error PaymentProcessor__ExchangeIsWhitelisted();
    error PaymentProcessor__ExchangeIsNotWhitelisted();
    error PaymentProcessor__FailedToTransferProceeds();
    error PaymentProcessor__InputArrayLengthCannotBeZero();
    error PaymentProcessor__InputArrayLengthMismatch();
    error PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
    error PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
    error PaymentProcessor__OfferHasExpired();
    error PaymentProcessor__OfferPriceMustEqualSalePrice();
    error PaymentProcessor__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
    error PaymentProcessor__OverpaidNativeFunds();
    error PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
    error PaymentProcessor__PricingBoundsAreImmutable();
    error PaymentProcessor__RanOutOfNativeFunds();
    error PaymentProcessor__SaleHasExpired();
    error PaymentProcessor__SalePriceAboveMaximumCeiling();
    error PaymentProcessor__SalePriceBelowMinimumFloor();
    error PaymentProcessor__SalePriceBelowSellerApprovedMinimum();
    error PaymentProcessor__SecurityPolicyDoesNotExist();
    error PaymentProcessor__SecurityPolicyOwnershipCannotBeTransferredToZeroAddress();
    error PaymentProcessor__SellerDidNotAuthorizeSale();
    error PaymentProcessor__SignatureAlreadyUsedOrRevoked();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();

    /// @dev Convenience to avoid magic number in bitmask get/set logic.
    uint256 private constant ONE = uint256(1);

    /// @notice The default admin role for NFT collections using Access Control.
    bytes32 private constant DEFAULT_ACCESS_CONTROL_ADMIN_ROLE = 0x00;

    /// @notice The default security policy id.
    uint256 public constant DEFAULT_SECURITY_POLICY_ID = 0;

    /// @notice The denominator used when calculating the marketplace fee.
    /// @dev    0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
    uint256 public constant FEE_DENOMINATOR = 10_000;

    /// @notice keccack256("OfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 tokenId,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant OFFER_APPROVAL_HASH = 0x2008a1ab898fdaa2d8f178bc39e807035d2d6e330dac5e42e913ca727ab56038;

    /// @notice keccack256("CollectionOfferApproval(uint8 protocol,bool collectionLevelOffer,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant COLLECTION_OFFER_APPROVAL_HASH = 0x0bc3075778b80a2341ce445063e81924b88d61eb5f21c815e8f9cc824af096d0;

    /// @notice keccack256("BundledOfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] itemSalePrices)")
    bytes32 public constant BUNDLED_OFFER_APPROVAL_HASH = 0x126520d0bca0cfa7e5852d004cc4335723ce67c638cbd55cd530fe992a089e7b;

    /// @notice keccack256("SaleApproval(uint8 protocol,bool sellerAcceptedOffer,address marketplace,uint256 marketplaceFeeNumerator,uint256 maxRoyaltyFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 tokenId,uint256 amount,uint256 minPrice,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant SALE_APPROVAL_HASH = 0xd3f4273db8ff5262b6bc5f6ee07d139463b4f826cce90c05165f63062f3686dc;

    /// @notice keccack256("BundledSaleApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] maxRoyaltyFeeNumerators,uint256[] itemPrices)")
    bytes32 public constant BUNDLED_SALE_APPROVAL_HASH = 0x80244acca7a02d7199149a3038653fc8cb10ca984341ec429a626fab631e1662;

    /// @dev Tracks the most recently created security profile id
    uint256 private lastSecurityPolicyId;

    /// @dev Mapping of token address (NFT collection) to a security policy id.
    mapping(address => uint256) private tokenSecurityPolicies;

    /// @dev Mapping of whitelisted exchange addresses, organized by security policy id.
    mapping(uint256 => mapping(address => bool)) private exchangeWhitelist;

    /// @dev Mapping of coin addresses that are approved for payments, organized by security policy id.
    mapping(uint256 => mapping(address => bool)) private paymentMethodWhitelist;

    /// @dev Mapping of security policy id to security policy settings.
    mapping(uint256 => SecurityPolicy) private securityPolicies;

    /**
     * @notice User-specific master nonce that allows buyers and sellers to efficiently cancel all listings or offers
     *         they made previously. The master nonce for a user only changes when they explicitly request to revoke all
     *         existing listings and offers.
     *
     * @dev    When prompting sellers to sign a listing or offer, marketplaces must query the current master nonce of
     *         the user and include it in the listing/offer signature data.
     */
    mapping(address => uint256) public masterNonces;

    /**
     * @dev The mapping key is the keccak256 hash of marketplace address and user address.
     *
     * @dev ```keccak256(abi.encodePacked(marketplace, user))```
     *
     * @dev The mapping value is another nested mapping of "slot" (key) to a bitmap (value) containing boolean flags
     *      indicating whether or not a nonce has been used or invalidated.
     *
     * @dev Marketplaces MUST track their own nonce by user, incrementing it for every signed listing or offer the user
     *      creates.  Listings and purchases may be executed out of order, and they may never be executed if orders
     *      are not matched prior to expriation.
     *
     * @dev The slot and the bit offset within the mapped value are computed as:
     *
     * @dev ```slot = nonce / 256;```
     * @dev ```offset = nonce % 256;```
     */
    mapping(bytes32 => mapping(uint256 => uint256)) private invalidatedSignatures;

    /**
     * @dev Mapping of token contract addresses to the address of the ERC-20 payment coin tokens are priced in.
     *      When unspecified, the default currency for collections is the native currency.
     *
     * @dev If the designated ERC-20 payment coin is not in the list of approved coins, sales cannot be executed
     *      until the designated coin is set to an approved payment coin.
     */
    mapping (address => address) public collectionPaymentCoins;

    /**
     * @dev Mapping of token contract addresses to the collection-level pricing boundaries (floor and ceiling price).
     */
    mapping (address => PricingBounds) private collectionPricingBounds;

    /**
     * @dev Mapping of token contract addresses to the token-level pricing boundaries (floor and ceiling price).
     */
    mapping (address => mapping (uint256 => PricingBounds)) private tokenPricingBounds;

    constructor(
        address defaultContractOwner_,
        uint32 defaultPushPaymentGasLimit_, 
        address[] memory defaultPaymentMethods) EIP712("PaymentProcessor", "1") {

        securityPolicies[DEFAULT_SECURITY_POLICY_ID] = SecurityPolicy({
            enforceExchangeWhitelist: false,
            enforcePaymentMethodWhitelist: true,
            enforcePricingConstraints: false,
            disablePrivateListings: false,
            disableDelegatedPurchases: false,
            disableEIP1271Signatures: false,
            disableExchangeWhitelistEOABypass: false,
            pushPaymentGasLimit: defaultPushPaymentGasLimit_,
            policyOwner: address(0)
        });

        emit CreatedOrUpdatedSecurityPolicy(
            DEFAULT_SECURITY_POLICY_ID, 
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            defaultPushPaymentGasLimit_,
            "DEFAULT SECURITY POLICY");

        for (uint256 i = 0; i < defaultPaymentMethods.length;) {
            address coin = defaultPaymentMethods[i];

            paymentMethodWhitelist[DEFAULT_SECURITY_POLICY_ID][coin] = true;
            emit PaymentMethodAddedToWhitelist(DEFAULT_SECURITY_POLICY_ID, coin);

            unchecked {
                ++i;
            }
        }

        _transferOwnership(defaultContractOwner_);
    }

    /**
     * @notice Allows Payment Processor contract owner to pause trading on this contract.  This is only to be used
     *         in case a future vulnerability emerges to allow a migration to an updated contract.
     *
     * @dev    Throws when caller is not the contract owner.
     * @dev    Throws when contract is already paused.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The contract has been placed in the `paused` state.
     * @dev    2. Trading is frozen.
     */
    function pause() external {
        _checkOwner();
        _pause();
    }

    /**
     * @notice Allows Payment Processor contract owner to resume trading on this contract.  This is only to be used
     *         in case a pause was not necessary and trading can safely resume.
     *
     * @dev    Throws when caller is not the contract owner.
     * @dev    Throws when contract is not currently paused.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The contract has been placed in the `unpaused` state.
     * @dev    2. Trading is resumed.
     */
    function unpause() external {
        _checkOwner();
        _unpause();
    }

    /**
     * @notice Allows any user to create a new security policy for the payment processor.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy id tracker has been incremented by `1`.
     * @dev    2. The security policy has been added to the security policies mapping.
     * @dev    3. The caller has been assigned as the owner of the security policy.
     * @dev    4. A `CreatedOrUpdatedSecurityPolicy` event has been emitted.
     *
     * @param  enforceExchangeWhitelist          Requires external exchange contracts be whitelisted to make buy calls.
     * @param  enforcePaymentMethodWhitelist     Requires that ERC-20 payment methods be pre-approved.
     * @param  enforcePricingConstraints         Allows the creator to specify exactly one approved payment method, 
     *                                           a minimum floor price and a maximum ceiling price.  
     *                                           When true, this value supercedes `enforcePaymentMethodWhitelist`.
     * @param  disablePrivateListings            Prevents private sales.
     * @param  disableDelegatedPurchases         Prevents delegated purchases.
     * @param  disableEIP1271Signatures          Prevents EIP-1271 compliant smart contracts such as multi-sig wallets
     *                                           from buying or selling.  Forces buyers and sellers to be EOAs.
     * @param  disableExchangeWhitelistEOABypass When exchange whitelists are enforced, prevents EOAs from executing
     *                                           purchases directly and bypassing whitelisted exchange contracts.
     * @param  pushPaymentGasLimit               The amount of gas to forward when pushing native proceeds.
     * @param  registryName                      A human readable name that describes the security policy.
     */
    function createSecurityPolicy(
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external override returns (uint256) {
        uint256 securityPolicyId;
        
        unchecked {
            securityPolicyId = ++lastSecurityPolicyId;
        }
        
        _createOrUpdateSecurityPolicy(
            securityPolicyId,
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName
        );

        return securityPolicyId;
    }

    /**
     * @notice Allows security policy owners to update existing security policies.
     * 
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified security policy id does not exist.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy details have been updated in the security policies mapping.
     * @dev    2. A `CreatedOrUpdatedSecurityPolicy` event has been emitted.
     *
     * @param  enforceExchangeWhitelist          Requires external exchange contracts be whitelisted to make buy calls.
     * @param  enforcePaymentMethodWhitelist     Requires that ERC-20 payment methods be pre-approved.
     * @param  enforcePricingConstraints         Allows the creator to specify exactly one approved payment method, 
     *                                           a minimum floor price and a maximum ceiling price.  
     *                                           When true, this value supercedes `enforcePaymentMethodWhitelist`.
     * @param  disablePrivateListings            Prevents private sales.
     * @param  disableDelegatedPurchases         Prevents delegated purchases.
     * @param  disableEIP1271Signatures          Prevents EIP-1271 compliant smart contracts such as multi-sig wallets
     *                                           from buying or selling.  Forces buyers and sellers to be EOAs.
     * @param  disableExchangeWhitelistEOABypass When exchange whitelists are enforced, prevents EOAs from executing
     *                                           purchases directly and bypassing whitelisted exchange contracts.
     * @param  pushPaymentGasLimit               The amount of gas to forward when pushing native proceeds.
     * @param  registryName                      A human readable name that describes the security policy.
     */
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
        string calldata registryName) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        _createOrUpdateSecurityPolicy(
            securityPolicyId,
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName
        );
    }

    /**
     * @notice Allow security policy owners to transfer ownership of their security policy to a new account.
     *
     * @dev    Throws when `newOwner` is the zero address.
     * @dev    Throws when caller is not the owner of the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy owner has been updated in the security policies mapping.
     * @dev    2. A `SecurityPolicyOwnershipTransferred` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  newOwner         The new policy owner address.
     */
    function transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) external override {
        if(newOwner == address(0)) {
            revert PaymentProcessor__SecurityPolicyOwnershipCannotBeTransferredToZeroAddress();
        }

        _transferSecurityPolicyOwnership(securityPolicyId, newOwner);
    }

    /**
     * @notice Allow security policy owners to transfer ownership of their security policy to the zero address.
     *         This can be done to make a security policy permanently immutable.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy owner has been set to the zero address in the security policies mapping.
     * @dev    2. A `SecurityPolicyOwnershipTransferred` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     */
    function renounceSecurityPolicyOwnership(uint256 securityPolicyId) external override {
        _transferSecurityPolicyOwnership(securityPolicyId, address(0));
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         set the security policy for their collection..
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified collection.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The `tokenSecurityPolicies` mapping has be updated to reflect the designated security policy id.
     * @dev    2. An `UpdatedCollectionSecurityPolicy` event has been emitted.
     *
     * @param  tokenAddress     The smart contract address of the NFT collection.
     * @param  securityPolicyId The security policy id to use for the collection.
     */
    function setCollectionSecurityPolicy(address tokenAddress, uint256 securityPolicyId) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if (securityPolicyId > lastSecurityPolicyId) {
            revert PaymentProcessor__SecurityPolicyDoesNotExist();
        }

        tokenSecurityPolicies[tokenAddress] = securityPolicyId;
        emit UpdatedCollectionSecurityPolicy(tokenAddress, securityPolicyId);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify the currency their collection is priced in.  Only applicable when `enforcePricingConstraints` 
     *         security setting is in effect for a collection.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the specified coin address non-zero and does not implement decimals() > 0.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The `collectionPaymentCoins` mapping has be updated to reflect the designated payment coin.
     * @dev    2. An `UpdatedCollectionPaymentCoin` event has been emitted.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  coin         The address of the designated ERC-20 payment coin smart contract.
     *                      Specify address(0) to designate native currency as the payment currency.
     */
    function setCollectionPaymentCoin(address tokenAddress, address coin) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);
        collectionPaymentCoins[tokenAddress] = coin;
        emit UpdatedCollectionPaymentCoin(tokenAddress, coin);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify their own bounded price at the collection level.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the previously set pricing bounds were set to be immutable.
     * @dev    Throws when the specified floor price is greater than the ceiling price.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The collection-level pricing bounds for the specified tokenAddress has been set.
     * @dev    2. An `UpdatedCollectionLevelPricingBoundaries` event has been emitted.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  pricingBounds Including the floor price, ceiling price, and an immutability flag.
     */
    function setCollectionPricingBounds(address tokenAddress, PricingBounds calldata pricingBounds) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if(collectionPricingBounds[tokenAddress].isImmutable) {
            revert PaymentProcessor__PricingBoundsAreImmutable();
        }

        if(pricingBounds.floorPrice > pricingBounds.ceilingPrice) {
            revert PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
        }
        
        collectionPricingBounds[tokenAddress] = pricingBounds;
        
        emit UpdatedCollectionLevelPricingBoundaries(
            tokenAddress, 
            pricingBounds.floorPrice, 
            pricingBounds.ceilingPrice);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify their own bounded price at the individual token level.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the lengths of the tokenIds and pricingBounds array don't match.
     * @dev    Throws when the tokenIds or pricingBounds array length is zero.     
     * @dev    Throws when the previously set pricing bounds of a token were set to be immutable.
     * @dev    Throws when the any of the specified floor prices is greater than the ceiling price for that token id.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The token-level pricing bounds for the specified tokenAddress and token ids has been set.
     * @dev    2. An `UpdatedTokenLevelPricingBoundaries` event has been emitted.
     *
     * @param  tokenAddress  The smart contract address of the NFT collection.
     * @param  tokenIds      An array of token ids for which pricing bounds are being set.
     * @param  pricingBounds An array of pricing bounds used to set the floor, ceiling and immutability flag on the 
     *                       individual token level.
     */
    function setTokenPricingBounds(
        address tokenAddress, 
        uint256[] calldata tokenIds, 
        PricingBounds[] calldata pricingBounds) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if(tokenIds.length != pricingBounds.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if(tokenIds.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        mapping (uint256 => PricingBounds) storage ptrTokenPricingBounds = tokenPricingBounds[tokenAddress];

        uint256 tokenId;
        for(uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            PricingBounds memory pricingBounds_ = pricingBounds[i];

            if(ptrTokenPricingBounds[tokenId].isImmutable) {
                revert PaymentProcessor__PricingBoundsAreImmutable();
            }

            if(pricingBounds_.floorPrice > pricingBounds_.ceilingPrice) {
                revert PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
            }

            ptrTokenPricingBounds[tokenId] = pricingBounds_;

            emit UpdatedTokenLevelPricingBoundaries(
                tokenAddress, 
                tokenId, 
                pricingBounds_.floorPrice, 
                pricingBounds_.ceilingPrice);
            
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows security policy owners to whitelist an exchange.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified address is address(0).
     * @dev    Throws when the specified address is already whitelisted under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `account` has been whitelisted in `exchangeWhitelist` mapping.
     * @dev    2. An `ExchangeAddedToWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  account          The address of the exchange to whitelist.
     */
    function whitelistExchange(uint256 securityPolicyId, address account) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        if (account == address(0)) {
            revert PaymentProcessor__AddressCannotBeZero();
        }

        mapping (address => bool) storage ptrExchangeWhitelist = exchangeWhitelist[securityPolicyId];

        if (ptrExchangeWhitelist[account]) {
            revert PaymentProcessor__ExchangeIsWhitelisted();
        }

        ptrExchangeWhitelist[account] = true;
        emit ExchangeAddedToWhitelist(securityPolicyId, account);
    }

    /**
     * @notice Allows security policy owners to remove an exchange from the whitelist.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified address is not whitelisted under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `account` has been unwhitelisted and removed from the `exchangeWhitelist` mapping.
     * @dev    2. An `ExchangeRemovedFromWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  account          The address of the exchange to unwhitelist.
     */
    function unwhitelistExchange(uint256 securityPolicyId, address account) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrExchangeWhitelist = exchangeWhitelist[securityPolicyId];

        if (!ptrExchangeWhitelist[account]) {
            revert PaymentProcessor__ExchangeIsNotWhitelisted();
        }

        delete ptrExchangeWhitelist[account];
        emit ExchangeRemovedFromWhitelist(securityPolicyId, account);
    }

    /**
     * @notice Allows security policy owners to approve a new coin for use as a payment currency.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified coin address is address(0).
     * @dev    Throws when the specified coin does not implement the decimals() that returns a non-zero value. 
     * @dev    Throws when the specified coin is already approved under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `coin` has been approved in `paymentMethodWhitelist` mapping.
     * @dev    2. A `PaymentMethodAddedToWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  coin             The address of the coin to approve.
     */
    function whitelistPaymentMethod(uint256 securityPolicyId, address coin) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrPaymentMethodWhitelist = paymentMethodWhitelist[securityPolicyId];

        if (ptrPaymentMethodWhitelist[coin]) {
            revert PaymentProcessor__CoinIsApproved();
        }

        ptrPaymentMethodWhitelist[coin] = true;
        emit PaymentMethodAddedToWhitelist(securityPolicyId, coin);
    }

    /**
     * @notice Allows security policy owners to remove a coin from the list of approved payment currencies.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified coin is not currently approved under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `coin` has been removed from the `paymentMethodWhitelist` mapping.
     * @dev    2. A `PaymentMethodRemovedFromWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  coin             The address of the coin to disapprove.
     */
    function unwhitelistPaymentMethod(uint256 securityPolicyId, address coin) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrPaymentMethodWhitelist = paymentMethodWhitelist[securityPolicyId];

        if (!ptrPaymentMethodWhitelist[coin]) {
            revert PaymentProcessor__CoinIsNotApproved();
        }

        delete ptrPaymentMethodWhitelist[coin];
        emit PaymentMethodRemovedFromWhitelist(securityPolicyId, coin);
    }

    /**
     * @notice Allows a user to revoke/cancel all prior signatures of listings and offers.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The user's master nonce has been incremented by `1` in contract storage, rendering all signed
     *            approvals using the prior nonce unusable.
     * @dev    2. A `MasterNonceInvalidated` event has been emitted.
     */
    function revokeMasterNonce() external override {
        emit MasterNonceInvalidated(masterNonces[_msgSender()], _msgSender());

        unchecked {
            ++masterNonces[_msgSender()];
        }
    }

    /**
     * @notice Allows a user to revoke/cancel a single, previously signed listing or offer by specifying the marketplace
     *         and nonce of the listing or offer.
     *
     * @dev    Throws when the user has already revoked the nonce.
     * @dev    Throws when the nonce was already used to successfully buy or sell an NFT.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The specified `nonce` for the specified `marketplace` and `msg.sender` pair has been revoked and can
     *            no longer be used to execute a sale or purchase.
     * @dev    2. A `RevokedListingOrOffer` event has been emitted.
     *
     * @param  marketplace The marketplace where the `msg.sender` signed the listing or offer.
     * @param  nonce       The nonce that was signed in the revoked listing or offer.
     */
    function revokeSingleNonce(address marketplace, uint256 nonce) external override {
        _checkAndInvalidateNonce(marketplace, _msgSender(), nonce, true);
    }

    /**
     * @notice Executes the sale of one ERC-721 or ERC-1155 token.
     *
     * @notice The seller's signature must be provided that proves that they approved the sale.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase.  There are two
     *         formats for this approval, one format to be used for collection-level offers when a specific token id is 
     *         not specified and one format to be used for item-level offers when a specific token id is specified.
     *
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         OfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice OR
     *
     * @notice ```
     *         CollectionOfferApproval(
     *           uint8 protocol,
     *           bool collectionLevelOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is ETH/native currency and the order was a collection or item offer.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the expiration timestamp of the listing or offer is in the past/expired.
     * @dev    Throws when the offer price is less than the seller-approved minimum price.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the seller or buyer is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         token or collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the token from the
     *         seller to the buyer.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuySingleListing` event has been emitted.
     * @dev    7. The token has been transferred from the seller to the buyer.
     *
     * @param saleDetails   See `MatchedOrder` struct.
     * @param signedListing See `SignatureECSA` struct.
     * @param signedOffer   See `SignatureECSA` struct.
     */
    function buySingleListing(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer
    ) external payable override {
        _requireNotPaused();
        if (!_executeMatchedOrderSale(msg.value, saleDetails, signedListing, signedOffer)) {
            revert PaymentProcessor__DispensingTokenWasUnsuccessful();
        }
    }

    /**
     * @notice Executes the sale of multiple ERC-721 or ERC-1155 tokens.
     *
     * @notice Sales may be a combination of native currency and ERC-20 payments.  Matched orders may be any combination
     *         of ERC-721 or ERC-1155 sales, as each matched order signature is validated independently against
     *         individual listings/orders associated with the matched orders.
     *
     * @notice A batch of orders will be partially filled in the case where an NFT is not available at the time of sale,
     *         but only if the method of payment is an ERC-20 token.  Partial fills are not supported for native
     *         payments to limit re-entrancy risks associated with issuing refunds.
     *
     * @notice The seller's signatures must be provided that proves that they approved the sales of each item.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each item.
     *         There are two formats for this approval, one format to be used for collection-level offers when a 
     *         specific token id is not specified and one format to be used for item-level offers when a specific token 
     *         id is specified.
     *
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         OfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice OR
     *
     * @notice ```
     *         CollectionOfferApproval(
     *           uint8 protocol,
     *           bool collectionLevelOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when any of the input arrays have mismatched lengths.
     * @dev    Throws when any of the input arrays are empty.
     * @dev    Throws when the the amount of native funds included isn't exactly equal to the sum of the native sale
     *         prices of individual items.
     * @dev    Throws when the the amount of ERC-20 funds approved is less than the sum of the ERC-20
     *         prices of individual items.
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    For each individual matched order to process:
     *
     * @dev    Throws when payment method is ETH/native currency and the order was a collection or item offer.
     * @dev    Throws when payment method is an ERC-20 coin and supplied ETH/native funds for item is not equal to zero.
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the expiration timestamp of the listing or offer is in the past/expired.
     * @dev    Throws when the offer price is less than the seller-approved minimum price.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the seller or buyer is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         token or collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the token from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    For each item:
     *
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuySingleListing` event has been emitted.
     * @dev    7. The token has been transferred from the seller to the buyer.
     *
     * @param saleDetailsArray An array of `MatchedOrder` structs.
     * @param signedListings   An array of `SignatureECDSA` structs.
     * @param signedOffers     An array of `SignatureECDSA` structs.
     */
    function buyBatchOfListings(
        MatchedOrder[] calldata saleDetailsArray,
        SignatureECDSA[] calldata signedListings,
        SignatureECDSA[] calldata signedOffers
    ) external payable override {
        _requireNotPaused();

        if (saleDetailsArray.length != signedListings.length || 
            saleDetailsArray.length != signedOffers.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if (saleDetailsArray.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        uint256 runningBalanceNativeProceeds = msg.value;

        MatchedOrder memory saleDetails;
        SignatureECDSA memory signedListing;
        SignatureECDSA memory signedOffer;
        uint256 msgValue;

        for (uint256 i = 0; i < saleDetailsArray.length;) {
            saleDetails = saleDetailsArray[i];
            signedListing = signedListings[i];
            signedOffer = signedOffers[i];
            msgValue = 0;

            if(saleDetails.paymentCoin == address(0)) {
                msgValue = saleDetails.offerPrice;

                if (runningBalanceNativeProceeds < msgValue) {
                    revert PaymentProcessor__RanOutOfNativeFunds();
                }

                unchecked {
                    runningBalanceNativeProceeds -= msgValue;
                }

                if (!_executeMatchedOrderSale(msgValue, saleDetails, signedListing, signedOffer)) {
                    revert PaymentProcessor__DispensingTokenWasUnsuccessful();
                }
            } else {
                _executeMatchedOrderSale(msgValue, saleDetails, signedListing, signedOffer);
            }

            unchecked {
                ++i;
            }
        }

        if (runningBalanceNativeProceeds > 0) {
            revert PaymentProcessor__OverpaidNativeFunds();
        }
    }

    /**
     * @notice Executes the bundled sale of ERC-721 or ERC-1155 token listed by a single seller for a single collection.
     *
     * @notice Orders will be partially filled in the case where an NFT is not available at the time of sale,
     *         but only if the method of payment is an ERC-20 token.  Partial fills are not supported for native
     *         payments to limit re-entrancy risks associated with issuing refunds.
     *
     * @notice The seller's signature must be provided that proves that they approved the sale of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledSaleApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] maxRoyaltyFeeNumerators,
     *           uint256[] itemPrices)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledOfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] itemSalePrices)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when the bundled items array has a length of zero.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the offer price does not equal the sum of the individual item prices in the listing.
     * @dev    Throws when the expiration timestamp of the offer is in the past/expired.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    For each item in the bundled listing:
     *
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when the expiration timestamp of the listing is in the past/expired.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         tokens in the collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the tokens from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuyBundledListingERC721` or `BuyBundledListingERC1155`  event has been emitted.
     * @dev    7. The tokens in the bundle has been transferred from the seller to the buyer.
     *
     * @param signedListing See `SignatureECSA` struct.
     * @param signedOffer   See `SignatureECSA` struct.
     * @param bundleDetails See `MatchedOrderBundleExtended` struct.
     * @param bundleItems   See `BundledItem` struct. 
     */
    function buyBundledListing(
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] calldata bundleItems) external payable override {
        _requireNotPaused();

        if (bundleItems.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        (uint256 securityPolicyId, SecurityPolicy storage securityPolicy) = 
            _getTokenSecurityPolicy(bundleDetails.bundleBase.tokenAddress);

        SignatureECDSA[] memory signedListingAsSingletonArray = new SignatureECDSA[](1);
        signedListingAsSingletonArray[0] = signedListing;

        (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) = 
        _validateBundledItems(
            false,
            securityPolicy,
            bundleDetails,
            bundleItems,
            signedListingAsSingletonArray
        );

        _validateBundledOffer(
            securityPolicyId,
            securityPolicy,
            bundleDetails.bundleBase,
            accumulator,
            signedOffer
        );

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: bundleDetails.bundleBase.delegatedPurchaser == address(0) ? bundleDetails.bundleBase.buyer : bundleDetails.bundleBase.delegatedPurchaser,
                paymentCoin: IERC20(bundleDetails.bundleBase.paymentCoin),
                funcPayout: bundleDetails.bundleBase.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: bundleDetails.bundleBase.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsBatch
        );

        if (bundleDetails.bundleBase.protocol == TokenProtocols.ERC1155) {
            emit BuyBundledListingERC1155(
                    bundleDetails.bundleBase.marketplace,
                    bundleDetails.bundleBase.tokenAddress,
                    bundleDetails.bundleBase.paymentCoin,
                    bundleDetails.bundleBase.buyer,
                    bundleDetails.seller,
                    unsuccessfulFills,
                    accumulator.tokenIds,
                    accumulator.amounts,
                    accumulator.salePrices);
        } else {
            emit BuyBundledListingERC721(
                    bundleDetails.bundleBase.marketplace,
                    bundleDetails.bundleBase.tokenAddress,
                    bundleDetails.bundleBase.paymentCoin,
                    bundleDetails.bundleBase.buyer,
                    bundleDetails.seller,
                    unsuccessfulFills,
                    accumulator.tokenIds,
                    accumulator.salePrices);
        }
    }

    /**
     * @notice Executes the bundled purchase of ERC-721 or ERC-1155 tokens individually listed for a single collection.
     *
     * @notice The seller's signatures must be provided that proves that they approved the sales of each item.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledOfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] itemSalePrices)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when any of the input arrays have mismatched lengths.
     * @dev    Throws when any of the input array have a length of zero.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the offer price does not equal the sum of the individual item prices in the listing.
     * @dev    Throws when the expiration timestamp of the offer is in the past/expired.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    For each item in the bundled listing:
     *
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when the expiration timestamp of the listing is in the past/expired.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         tokens in the collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the tokens from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `SweepCollectionERC721` or `SweepCollectionERC1155`  event has been emitted.
     * @dev    7. The tokens in the bundle has been transferred from the seller to the buyer.
     *
     * @param signedOffer    See `SignatureECSA` struct.
     * @param bundleDetails  See `MatchedOrderBundleBase` struct.
     * @param bundleItems    See `BundledItem` struct. 
     * @param signedListings See `SignatureECSA` struct.
     */
    function sweepCollection(
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleBase memory bundleDetails,
        BundledItem[] calldata bundleItems,
        SignatureECDSA[] calldata signedListings) external payable override {
        _requireNotPaused();

        if (bundleItems.length != signedListings.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if (bundleItems.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        (uint256 securityPolicyId, SecurityPolicy storage securityPolicy) = 
            _getTokenSecurityPolicy(bundleDetails.tokenAddress);

        (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) = 
        _validateBundledItems(
            true,
            securityPolicy,
            MatchedOrderBundleExtended({
                bundleBase: bundleDetails,
                seller: address(0),
                listingNonce: 0,
                listingExpiration: 0
            }),
            bundleItems,
            signedListings
        );

        _validateBundledOffer(
            securityPolicyId,
            securityPolicy,
            bundleDetails,
            accumulator,
            signedOffer
        );

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: bundleDetails.delegatedPurchaser == address(0) ? bundleDetails.buyer : bundleDetails.delegatedPurchaser,
                paymentCoin: IERC20(bundleDetails.paymentCoin),
                funcPayout: bundleDetails.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: bundleDetails.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsBatch
        );

        if (bundleDetails.protocol == TokenProtocols.ERC1155) {
            emit SweepCollectionERC1155(
                    bundleDetails.marketplace,
                    bundleDetails.tokenAddress,
                    bundleDetails.paymentCoin,
                    bundleDetails.buyer,
                    unsuccessfulFills,
                    accumulator.sellers,
                    accumulator.tokenIds,
                    accumulator.amounts,
                    accumulator.salePrices);
        } else {
            emit SweepCollectionERC721(
                    bundleDetails.marketplace,
                    bundleDetails.tokenAddress,
                    bundleDetails.paymentCoin,
                    bundleDetails.buyer,
                    unsuccessfulFills,
                    accumulator.sellers,
                    accumulator.tokenIds,
                    accumulator.salePrices);
        }
    }

    /**
     * @notice Returns the EIP-712 domain separator for this contract.
     */
    function getDomainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Returns the security policy details for the specified security policy id.
     * 
     * @param  securityPolicyId The security policy id to lookup.
     * @return securityPolicy   The security policy details.
     */
    function getSecurityPolicy(uint256 securityPolicyId) external view override returns (SecurityPolicy memory) {
        return securityPolicies[securityPolicyId];
    }

    /**
     * @notice Returns whitelist status of the exchange address for the specified security policy id.
     *
     * @param  securityPolicyId The security policy id to lookup.
     * @param  account          The address to check.
     * @return isWhitelisted    True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(uint256 securityPolicyId, address account) external view override returns (bool) {
        return exchangeWhitelist[securityPolicyId][account];
    }

    /**
     * @notice Returns approval status of the payment coin address for the specified security policy id.
     *
     * @param  securityPolicyId        The security policy id to lookup.
     * @param  coin                    The coin address to check.
     * @return isPaymentMethodApproved True if the coin address is approved, false otherwise.
     */
    function isPaymentMethodApproved(uint256 securityPolicyId, address coin) external view override returns (bool) {
        return paymentMethodWhitelist[securityPolicyId][coin];
    }

    /**
     * @notice Returns the current security policy id for the specified collection address.
     * 
     * @param  collectionAddress The address of the collection to lookup.
     * @return securityPolicyId  The current security policy id for the specifed collection.
     */
    function getTokenSecurityPolicyId(address collectionAddress) external view override returns (uint256) {
        return tokenSecurityPolicies[collectionAddress];
    }

    /**
     * @notice Returns whether or not the price of a collection is immutable.
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @return True if the floor and ceiling price for the specified token contract has been set immutably, false otherwise.
     */
    function isCollectionPricingImmutable(address tokenAddress) external view override returns (bool) {
        return collectionPricingBounds[tokenAddress].isImmutable;
    }

    /**
     * @notice Returns whether or not the price of a specific token is immutable.
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return True if the floor and ceiling price for the specified token contract and tokenId has been set immutably, false otherwise.
     */
    function isTokenPricingImmutable(address tokenAddress, uint256 tokenId) external view override returns (bool) {
        return tokenPricingBounds[tokenAddress][tokenId].isImmutable;
    }

    /**
     * @notice Gets the floor price for the specified nft contract address and token id.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return The floor price.
     */
    function getFloorPrice(address tokenAddress, uint256 tokenId) external view override returns (uint256) {
        (uint256 floorPrice,) = _getFloorAndCeilingPrices(tokenAddress, tokenId);
        return floorPrice;
    }

    /**
     * @notice Gets the ceiling price for the specified nft contract address and token id.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return The ceiling price.
     */
    function getCeilingPrice(address tokenAddress, uint256 tokenId) external view override returns (uint256) {
        (, uint256 ceilingPrice) = _getFloorAndCeilingPrices(tokenAddress, tokenId);
        return ceilingPrice;
    }

    /**
     * @notice ERC-165 Interface Introspection Support.
     * @dev    Supports `IPaymentProcessor` interface as well as parent contract interfaces.
     * @param  interfaceId The interface to query.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IPaymentProcessor).interfaceId || super.supportsInterface(interfaceId);
    }

    function _payoutNativeCurrency(
        address payee, 
        address /*payer*/, 
        IERC20 /*paymentCoin*/, 
        uint256 proceeds, 
        uint256 gasLimit_) internal {
        _pushProceeds(payee, proceeds, gasLimit_);
    }

    function _payoutCoinCurrency(
        address payee, 
        address payer, 
        IERC20 paymentCoin, 
        uint256 proceeds, 
        uint256 /*gasLimit_*/) internal {
        SafeERC20.safeTransferFrom(paymentCoin, payer, payee, proceeds);
    }

    function _dispenseERC721Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 /*amount*/) internal returns (bool) {
        try IERC721(tokenAddress).transferFrom(from, to, tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    function _dispenseERC1155Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount) internal returns (bool) {
        try IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "") {
            return true;
        } catch {
            return false;
        }
    }

    function _requireCallerIsNFTOrContractOwnerOrAdmin(address tokenAddress) internal view {
        bool callerHasPermissions = false;
        
        callerHasPermissions = _msgSender() == tokenAddress;
        if(!callerHasPermissions) {
            try IOwnable(tokenAddress).owner() returns (address contractOwner) {
                callerHasPermissions = _msgSender() == contractOwner;
            } catch {}

            if(!callerHasPermissions) {
                try IAccessControl(tokenAddress).hasRole(DEFAULT_ACCESS_CONTROL_ADMIN_ROLE, _msgSender()) 
                    returns (bool callerIsContractAdmin) {
                    callerHasPermissions = callerIsContractAdmin;
                } catch {}
            }
        }

        if(!callerHasPermissions) {
            revert PaymentProcessor__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
        }
    }

    function _verifyPaymentCoinIsApproved(
        uint256 securityPolicyId, 
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        address tokenAddress, 
        address coin) internal view virtual {
        if (enforcePricingConstraints) {
            if(collectionPaymentCoins[tokenAddress] != coin) {
                revert PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
            }
        } else if (enforcePaymentMethodWhitelist) {
            if (!paymentMethodWhitelist[securityPolicyId][coin]) {
                revert PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
            }
        }
    }

    function _createOrUpdateSecurityPolicy(
        uint256 securityPolicyId,
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) private {

        securityPolicies[securityPolicyId] = SecurityPolicy({
            enforceExchangeWhitelist: enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist: enforcePaymentMethodWhitelist,
            enforcePricingConstraints: enforcePricingConstraints,
            disablePrivateListings: disablePrivateListings,
            disableDelegatedPurchases: disableDelegatedPurchases,
            disableEIP1271Signatures: disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass: disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit: pushPaymentGasLimit,
            policyOwner: _msgSender()
        });

        emit CreatedOrUpdatedSecurityPolicy(
            securityPolicyId, 
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName);
    }

    function _transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) private {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        SecurityPolicy storage securityPolicy = securityPolicies[securityPolicyId];

        address oldOwner = securityPolicy.policyOwner;
        securityPolicy.policyOwner = newOwner;
        emit SecurityPolicyOwnershipTransferred(oldOwner, newOwner);
    }

    function _executeMatchedOrderSale(
        uint256 msgValue,
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer
    ) private returns (bool tokenDispensedSuccessfully) {
        uint256 securityPolicyId = tokenSecurityPolicies[saleDetails.tokenAddress];
        SecurityPolicy memory securityPolicy = securityPolicies[securityPolicyId];

        if (saleDetails.paymentCoin == address(0)) {
            if (saleDetails.offerPrice != msgValue) {
                revert PaymentProcessor__OfferPriceMustEqualSalePrice();
            }

            if (saleDetails.sellerAcceptedOffer || saleDetails.seller == tx.origin) {
                revert PaymentProcessor__CollectionLevelOrItemLevelOffersCanOnlyBeMadeUsingERC20PaymentMethods();
            }
        } else {
            if (msgValue > 0) {
                revert PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
            }

            _verifyPaymentCoinIsApproved(
                securityPolicyId, 
                securityPolicy.enforcePaymentMethodWhitelist, 
                securityPolicy.enforcePricingConstraints,
                saleDetails.tokenAddress, 
                saleDetails.paymentCoin);
        }
        
        if (saleDetails.protocol == TokenProtocols.ERC1155) {
            if (saleDetails.amount == 0) {
                revert PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
            }
        } else {
            if (saleDetails.amount != ONE) {
                revert PaymentProcessor__AmountForERC721SalesMustEqualOne();
            }
        }

        if (block.timestamp > saleDetails.listingExpiration) {
            revert PaymentProcessor__SaleHasExpired();
        }

        if (block.timestamp > saleDetails.offerExpiration) {
            revert PaymentProcessor__OfferHasExpired();
        }

        if (saleDetails.offerPrice < saleDetails.listingMinPrice) {
            revert PaymentProcessor__SalePriceBelowSellerApprovedMinimum();
        }

        if (saleDetails.marketplaceFeeNumerator + saleDetails.maxRoyaltyFeeNumerator > FEE_DENOMINATOR) {
            revert PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
        }

        if (saleDetails.privateBuyer != address(0)) {
            if (saleDetails.buyer != saleDetails.privateBuyer) {
                revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
            }
    
            if (securityPolicy.disablePrivateListings) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
            }
        }

        if (saleDetails.delegatedPurchaser != address(0)) {
            if (_msgSender() != saleDetails.delegatedPurchaser) {
                revert PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
            }

            if(securityPolicy.disableDelegatedPurchases) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
            }
        }

        if(securityPolicy.disableEIP1271Signatures) {
            if (saleDetails.seller.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }

            if (saleDetails.buyer.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }
        }

        if (securityPolicy.enforceExchangeWhitelist) {
            if (_msgSender() != tx.origin) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__CallerIsNotWhitelistedMarketplace();
                }
            } else if (securityPolicy.disableExchangeWhitelistEOABypass) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
                }
            }
        }

        if (securityPolicy.enforcePricingConstraints) {
            if (saleDetails.paymentCoin == address(0)) {
                if(collectionPaymentCoins[saleDetails.tokenAddress] != address(0)) {
                    revert PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
                }
            }

            _verifySalePriceInRange(
                saleDetails.tokenAddress, 
                saleDetails.tokenId, 
                saleDetails.amount, 
                saleDetails.offerPrice);
        }

        _verifySignedItemListing(saleDetails, signedListing);

        if (saleDetails.collectionLevelOffer) {
            _verifySignedCollectionOffer(saleDetails, signedOffer);
        } else {
            _verifySignedItemOffer(saleDetails, signedOffer);
        }

        MatchedOrder[] memory saleDetailsSingletonBatch = new MatchedOrder[](1);
        saleDetailsSingletonBatch[0] = saleDetails;

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: saleDetails.delegatedPurchaser == address(0) ? saleDetails.buyer : saleDetails.delegatedPurchaser,
                paymentCoin: IERC20(saleDetails.paymentCoin),
                funcPayout: saleDetails.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: saleDetails.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsSingletonBatch
        );

        tokenDispensedSuccessfully = !unsuccessfulFills[0];

        if (tokenDispensedSuccessfully) {
            emit BuySingleListing(
                saleDetails.marketplace,
                saleDetails.tokenAddress,
                saleDetails.paymentCoin,
                saleDetails.buyer,
                saleDetails.seller,
                saleDetails.tokenId,
                saleDetails.amount,
                saleDetails.offerPrice);
        }
    }

    function _validateBundledOffer(
        uint256 securityPolicyId,
        SecurityPolicy storage securityPolicy,
        MatchedOrderBundleBase memory bundleDetails,
        Accumulator memory accumulator,
        SignatureECDSA memory signedOffer) private {
        if (bundleDetails.paymentCoin != address(0)) {
            if (msg.value > 0) {
                revert PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
            }
    
            _verifyPaymentCoinIsApproved(
                securityPolicyId, 
                securityPolicy.enforcePaymentMethodWhitelist, 
                securityPolicy.enforcePricingConstraints,
                bundleDetails.tokenAddress, 
                bundleDetails.paymentCoin);
        } else {
            if (msg.value != bundleDetails.offerPrice) {
                revert PaymentProcessor__OfferPriceMustEqualSalePrice();
            }

            if (securityPolicy.enforcePricingConstraints) {
                if(collectionPaymentCoins[bundleDetails.tokenAddress] != address(0)) {
                    revert PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
                }
            }
        }

        if (block.timestamp > bundleDetails.offerExpiration) {
            revert PaymentProcessor__OfferHasExpired();
        }

        if (bundleDetails.delegatedPurchaser != address(0)) {
            if (_msgSender() != bundleDetails.delegatedPurchaser) {
                revert PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
            }

            if(securityPolicy.disableDelegatedPurchases) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
            }
        }

        if(securityPolicy.disableEIP1271Signatures) {
            if (bundleDetails.buyer.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }
        }

        if (securityPolicy.enforceExchangeWhitelist) {
            if (_msgSender() != tx.origin) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__CallerIsNotWhitelistedMarketplace();
                }
            } else if (securityPolicy.disableExchangeWhitelistEOABypass) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
                }
            }
        }

        if (accumulator.sumListingPrices != bundleDetails.offerPrice) {
            revert PaymentProcessor__BundledOfferPriceMustEqualSumOfAllListingPrices();
        }

        _verifySignedOfferForBundledItems(
            keccak256(abi.encodePacked(accumulator.tokenIds)),
            keccak256(abi.encodePacked(accumulator.amounts)),
            keccak256(abi.encodePacked(accumulator.salePrices)),
            bundleDetails,
            signedOffer
        );
    }

    function _validateBundledItems(
        bool individualListings,
        SecurityPolicy storage securityPolicy,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] memory bundledOfferItems,
        SignatureECDSA[] memory signedListings) 
        private returns (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) {

        saleDetailsBatch = new MatchedOrder[](bundledOfferItems.length);
        accumulator = Accumulator({
            tokenIds: new uint256[](bundledOfferItems.length),
            amounts: new uint256[](bundledOfferItems.length),
            salePrices: new uint256[](bundledOfferItems.length),
            maxRoyaltyFeeNumerators: new uint256[](bundledOfferItems.length),
            sellers: new address[](bundledOfferItems.length),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < bundledOfferItems.length;) {

            address seller = bundleDetails.seller;
            uint256 listingNonce = bundleDetails.listingNonce;
            uint256 listingExpiration = bundleDetails.listingExpiration;

            if (individualListings) {
                seller = bundledOfferItems[i].seller;
                listingNonce = bundledOfferItems[i].listingNonce;
                listingExpiration = bundledOfferItems[i].listingExpiration;
            }
            
            MatchedOrder memory saleDetails = 
                MatchedOrder({
                    sellerAcceptedOffer: false,
                    collectionLevelOffer: false,
                    protocol: bundleDetails.bundleBase.protocol,
                    paymentCoin: bundleDetails.bundleBase.paymentCoin,
                    tokenAddress: bundleDetails.bundleBase.tokenAddress,
                    seller: seller,
                    privateBuyer: bundleDetails.bundleBase.privateBuyer,
                    buyer: bundleDetails.bundleBase.buyer,
                    delegatedPurchaser: bundleDetails.bundleBase.delegatedPurchaser,
                    marketplace: bundleDetails.bundleBase.marketplace,
                    marketplaceFeeNumerator: bundleDetails.bundleBase.marketplaceFeeNumerator,
                    maxRoyaltyFeeNumerator: bundledOfferItems[i].maxRoyaltyFeeNumerator,
                    listingNonce: listingNonce,
                    offerNonce: bundleDetails.bundleBase.offerNonce,
                    listingMinPrice: bundledOfferItems[i].itemPrice,
                    offerPrice: bundledOfferItems[i].itemPrice,
                    listingExpiration: listingExpiration,
                    offerExpiration: bundleDetails.bundleBase.offerExpiration,
                    tokenId: bundledOfferItems[i].tokenId,
                    amount: bundledOfferItems[i].amount
                });

            saleDetailsBatch[i] = saleDetails;

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails.maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = saleDetails.seller;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            if (saleDetails.protocol == TokenProtocols.ERC1155) {
                if (saleDetails.amount == 0) {
                    revert PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
                }
            } else {
                if (saleDetails.amount != ONE) {
                    revert PaymentProcessor__AmountForERC721SalesMustEqualOne();
                }
            }

            if (saleDetails.marketplaceFeeNumerator + saleDetails.maxRoyaltyFeeNumerator > FEE_DENOMINATOR) {
                revert PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
            }

            if (securityPolicy.enforcePricingConstraints) {
                _verifySalePriceInRange(
                    saleDetails.tokenAddress, 
                    saleDetails.tokenId, 
                    saleDetails.amount, 
                    saleDetails.offerPrice);
            }
   
            if (individualListings) {
                if (block.timestamp > saleDetails.listingExpiration) {
                    revert PaymentProcessor__SaleHasExpired();
                }

                if (saleDetails.privateBuyer != address(0)) {
                    if (saleDetails.buyer != saleDetails.privateBuyer) {
                        revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
                    }
    
                    if (securityPolicy.disablePrivateListings) {
                        revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
                    }
                }
        
                if(securityPolicy.disableEIP1271Signatures) {
                    if (saleDetails.seller.code.length > 0) {
                        revert PaymentProcessor__EIP1271SignaturesAreDisabled();
                    }
                }
    
                _verifySignedItemListing(saleDetails, signedListings[i]);
            }

            unchecked {
                ++i;
            }
        }

        if(!individualListings) {
            if (block.timestamp > bundleDetails.listingExpiration) {
                revert PaymentProcessor__SaleHasExpired();
            }

            if (bundleDetails.bundleBase.privateBuyer != address(0)) {
                if (bundleDetails.bundleBase.buyer != bundleDetails.bundleBase.privateBuyer) {
                    revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
                }
    
                if (securityPolicy.disablePrivateListings) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
                }
            }

            if(securityPolicy.disableEIP1271Signatures) {
                if (bundleDetails.seller.code.length > 0) {
                    revert PaymentProcessor__EIP1271SignaturesAreDisabled();
                }
            }

            _verifySignedBundleListing(
                AccumulatorHashes({
                    tokenIdsKeccakHash: keccak256(abi.encodePacked(accumulator.tokenIds)),
                    amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
                    maxRoyaltyFeeNumeratorsKeccakHash: keccak256(abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)),
                    itemPricesKeccakHash: keccak256(abi.encodePacked(accumulator.salePrices))
                }),
                bundleDetails, 
                signedListings[0]);
        }
    }

    function _verifySignedItemOffer(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedOffer) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        OFFER_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.delegatedPurchaser,
                        saleDetails.buyer,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.amount,
                        saleDetails.offerPrice
                    ),
                    abi.encode(
                        saleDetails.offerExpiration,
                        saleDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.buyer, 
                            saleDetails.offerNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.buyer, digest, signedOffer);
        } else if (saleDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedCollectionOffer(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedOffer) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        COLLECTION_OFFER_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.collectionLevelOffer,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.delegatedPurchaser,
                        saleDetails.buyer,
                        saleDetails.tokenAddress,
                        saleDetails.amount,
                        saleDetails.offerPrice
                    ),
                    abi.encode(
                        saleDetails.offerExpiration,
                        saleDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.buyer, 
                            saleDetails.offerNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.buyer, digest, signedOffer);
        } else if (saleDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedOfferForBundledItems(
        bytes32 tokenIdsKeccakHash,
        bytes32 amountsKeccakHash,
        bytes32 salePricesKeccakHash,
        MatchedOrderBundleBase memory bundledOfferDetails,
        SignatureECDSA memory signedOffer) private {

        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_OFFER_APPROVAL_HASH,
                        uint8(bundledOfferDetails.protocol),
                        bundledOfferDetails.marketplace,
                        bundledOfferDetails.marketplaceFeeNumerator,
                        bundledOfferDetails.delegatedPurchaser,
                        bundledOfferDetails.buyer,
                        bundledOfferDetails.tokenAddress,
                        bundledOfferDetails.offerPrice
                    ),
                    abi.encode(
                        bundledOfferDetails.offerExpiration,
                        bundledOfferDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            bundledOfferDetails.marketplace, 
                            bundledOfferDetails.buyer, 
                            bundledOfferDetails.offerNonce,
                            false
                        ),
                        bundledOfferDetails.paymentCoin,
                        tokenIdsKeccakHash,
                        amountsKeccakHash,
                        salePricesKeccakHash
                    )
                )
            )
        );

        if(bundledOfferDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(bundledOfferDetails.buyer, digest, signedOffer);
        } else if (bundledOfferDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedBundleListing(
        AccumulatorHashes memory accumulatorHashes,
        MatchedOrderBundleExtended memory bundleDetails,
        SignatureECDSA memory signedListing) private {

        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_SALE_APPROVAL_HASH,
                        uint8(bundleDetails.bundleBase.protocol),
                        bundleDetails.bundleBase.marketplace,
                        bundleDetails.bundleBase.marketplaceFeeNumerator,
                        bundleDetails.bundleBase.privateBuyer,
                        bundleDetails.seller,
                        bundleDetails.bundleBase.tokenAddress
                    ),
                    abi.encode(
                        bundleDetails.listingExpiration,
                        bundleDetails.listingNonce,
                        _checkAndInvalidateNonce(
                            bundleDetails.bundleBase.marketplace, 
                            bundleDetails.seller, 
                            bundleDetails.listingNonce,
                            false
                        ),
                        bundleDetails.bundleBase.paymentCoin,
                        accumulatorHashes.tokenIdsKeccakHash,
                        accumulatorHashes.amountsKeccakHash,
                        accumulatorHashes.maxRoyaltyFeeNumeratorsKeccakHash,
                        accumulatorHashes.itemPricesKeccakHash
                    )
                )
            )
        );

        if(bundleDetails.seller.code.length > 0) {
            _verifyEIP1271Signature(bundleDetails.seller, digest, signedListing);
        } else if (bundleDetails.seller != ECDSA.recover(digest, signedListing.v, signedListing.r, signedListing.s)) {
            revert PaymentProcessor__SellerDidNotAuthorizeSale();
        }
    }

    function _verifySignedItemListing(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        SALE_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.sellerAcceptedOffer,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.maxRoyaltyFeeNumerator,
                        saleDetails.privateBuyer
                    ),
                    abi.encode(
                        saleDetails.seller,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.amount,
                        saleDetails.listingMinPrice,
                        saleDetails.listingExpiration,
                        saleDetails.listingNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.seller, 
                            saleDetails.listingNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.seller.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.seller, digest, signedListing);
        } else if (saleDetails.seller != ECDSA.recover(digest, signedListing.v, signedListing.r, signedListing.s)) {
            revert PaymentProcessor__SellerDidNotAuthorizeSale();
        }
    }

    function _checkAndInvalidateNonce(
        address marketplace, 
        address account, 
        uint256 nonce, 
        bool wasCancellation) private returns (uint256) {

        mapping(uint256 => uint256) storage ptrInvalidatedSignatureBitmap =
            invalidatedSignatures[keccak256(abi.encodePacked(marketplace, account))];

        unchecked {
            uint256 slot = nonce / 256;
            uint256 offset = nonce % 256;
            uint256 slotValue = ptrInvalidatedSignatureBitmap[slot];

            if (((slotValue >> offset) & ONE) == ONE) {
                revert PaymentProcessor__SignatureAlreadyUsedOrRevoked();
            }

            ptrInvalidatedSignatureBitmap[slot] = (slotValue | ONE << offset);
        }

        emit NonceInvalidated(nonce, account, marketplace, wasCancellation);

        return masterNonces[account];
    }

    function _computeAndDistributeProceeds(
        ComputeAndDistributeProceedsArgs memory args,
        MatchedOrder[] memory saleDetailsBatch) private returns (bool[] memory unsuccessfulFills) {

        unsuccessfulFills = new bool[](saleDetailsBatch.length);

        PayoutsAccumulator memory accumulator = PayoutsAccumulator({
            lastSeller: address(0),
            lastMarketplace: address(0),
            lastRoyaltyRecipient: address(0),
            accumulatedSellerProceeds: 0,
            accumulatedMarketplaceProceeds: 0,
            accumulatedRoyaltyProceeds: 0
        });

        for (uint256 i = 0; i < saleDetailsBatch.length;) {
            MatchedOrder memory saleDetails = saleDetailsBatch[i];

            bool successfullyDispensedToken = 
                args.funcDispenseToken(
                    saleDetails.seller, 
                    saleDetails.buyer, 
                    saleDetails.tokenAddress, 
                    saleDetails.tokenId, 
                    saleDetails.amount);

            if (!successfullyDispensedToken) {
                if (address(args.paymentCoin) == address(0)) {
                    revert PaymentProcessor__DispensingTokenWasUnsuccessful();
                }

                unsuccessfulFills[i] = true;
            } else {
                SplitProceeds memory proceeds =
                    _computePaymentSplits(
                        saleDetails.offerPrice,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.maxRoyaltyFeeNumerator
                    );
    
                if (proceeds.royaltyRecipient != accumulator.lastRoyaltyRecipient) {
                    if(accumulator.accumulatedRoyaltyProceeds > 0) {
                        args.funcPayout(accumulator.lastRoyaltyRecipient, args.purchaser, args.paymentCoin, accumulator.accumulatedRoyaltyProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastRoyaltyRecipient = proceeds.royaltyRecipient;
                    accumulator.accumulatedRoyaltyProceeds = 0;
                }
    
                if (saleDetails.marketplace != accumulator.lastMarketplace) {
                    if(accumulator.accumulatedMarketplaceProceeds > 0) {
                        args.funcPayout(accumulator.lastMarketplace, args.purchaser, args.paymentCoin, accumulator.accumulatedMarketplaceProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastMarketplace = saleDetails.marketplace;
                    accumulator.accumulatedMarketplaceProceeds = 0;
                }
    
                if (saleDetails.seller != accumulator.lastSeller) {
                    if(accumulator.accumulatedSellerProceeds > 0) {
                        args.funcPayout(accumulator.lastSeller, args.purchaser, args.paymentCoin, accumulator.accumulatedSellerProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastSeller = saleDetails.seller;
                    accumulator.accumulatedSellerProceeds = 0;
                }

                unchecked {
                    accumulator.accumulatedRoyaltyProceeds += proceeds.royaltyProceeds;
                    accumulator.accumulatedMarketplaceProceeds += proceeds.marketplaceProceeds;
                    accumulator.accumulatedSellerProceeds += proceeds.sellerProceeds;
                }
            }

            unchecked {
                ++i;
            }
        }

        if(accumulator.accumulatedRoyaltyProceeds > 0) {
            args.funcPayout(accumulator.lastRoyaltyRecipient, args.purchaser, args.paymentCoin, accumulator.accumulatedRoyaltyProceeds, args.pushPaymentGasLimit);
        }

        if(accumulator.accumulatedMarketplaceProceeds > 0) {
            args.funcPayout(accumulator.lastMarketplace, args.purchaser, args.paymentCoin, accumulator.accumulatedMarketplaceProceeds, args.pushPaymentGasLimit);
        }

        if(accumulator.accumulatedSellerProceeds > 0) {
            args.funcPayout(accumulator.lastSeller, args.purchaser, args.paymentCoin, accumulator.accumulatedSellerProceeds, args.pushPaymentGasLimit);
        }

        return unsuccessfulFills;
    }

    function _pushProceeds(address to, uint256 proceeds, uint256 pushPaymentGasLimit_) private {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(pushPaymentGasLimit_, to, proceeds, 0, 0, 0, 0)
        }

        if (!success) {
            revert PaymentProcessor__FailedToTransferProceeds();
        }
    }

    function _computePaymentSplits(
        uint256 salePrice,
        address tokenAddress,
        uint256 tokenId,
        address marketplaceFeeRecipient,
        uint256 marketplaceFeeNumerator,
        uint256 maxRoyaltyFeeNumerator) private view returns (SplitProceeds memory proceeds) {

        proceeds.sellerProceeds = salePrice;

        try IERC2981(tokenAddress).royaltyInfo(
            tokenId, 
            salePrice) 
            returns (address royaltyReceiver, uint256 royaltyAmount) {
            if (royaltyReceiver == address(0)) {
                royaltyAmount = 0;
            }

            if (royaltyAmount > 0) {
                if (royaltyAmount > (salePrice * maxRoyaltyFeeNumerator) / FEE_DENOMINATOR) {
                    revert PaymentProcessor__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
                }

                proceeds.royaltyRecipient = royaltyReceiver;
                proceeds.royaltyProceeds = royaltyAmount;

                unchecked {
                    proceeds.sellerProceeds -= royaltyAmount;
                }
            }
        } catch (bytes memory) {}

        proceeds.marketplaceProceeds =
            marketplaceFeeRecipient != address(0) ? (salePrice * marketplaceFeeNumerator) / FEE_DENOMINATOR : 0;
        if (proceeds.marketplaceProceeds > 0) {
            unchecked {
                proceeds.sellerProceeds -= proceeds.marketplaceProceeds;
            }
        }
    }

    function _getTokenSecurityPolicy(address tokenAddress) private view returns (uint256, SecurityPolicy storage) {
        uint256 securityPolicyId = tokenSecurityPolicies[tokenAddress];
        SecurityPolicy storage securityPolicy = securityPolicies[securityPolicyId];
        return (securityPolicyId, securityPolicy);
    }

    function _requireCallerOwnsSecurityPolicy(uint256 securityPolicyId) private view {
        if(_msgSender() != securityPolicies[securityPolicyId].policyOwner) {
            revert PaymentProcessor__CallerDoesNotOwnSecurityPolicy();
        }
    }

    function _getFloorAndCeilingPrices(
        address tokenAddress, 
        uint256 tokenId) private view returns (uint256, uint256) {

        PricingBounds memory tokenLevelPricingBounds = tokenPricingBounds[tokenAddress][tokenId];
        if (tokenLevelPricingBounds.isEnabled) {
            return (tokenLevelPricingBounds.floorPrice, tokenLevelPricingBounds.ceilingPrice);
        } else {
            PricingBounds memory collectionLevelPricingBounds = collectionPricingBounds[tokenAddress];
            if (collectionLevelPricingBounds.isEnabled) {
                return (collectionLevelPricingBounds.floorPrice, collectionLevelPricingBounds.ceilingPrice);
            }
        }

        return (0, type(uint256).max);
    }

    function _verifySalePriceInRange(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount, 
        uint256 salePrice) private view {

        uint256 salePricePerUnit = salePrice / amount;

        (uint256 floorPrice, uint256 ceilingPrice) = _getFloorAndCeilingPrices(tokenAddress, tokenId);

        if(salePricePerUnit < floorPrice) {
            revert PaymentProcessor__SalePriceBelowMinimumFloor();
        }

        if(salePricePerUnit > ceilingPrice) {
            revert PaymentProcessor__SalePriceAboveMaximumCeiling();
        }
    }

    function _verifyEIP1271Signature(
        address signer, 
        bytes32 hash, 
        SignatureECDSA memory signatureComponents) private view {
        bool isValidSignatureNow;
        
        try IERC1271(signer).isValidSignature(
            hash, 
            abi.encodePacked(signatureComponents.r, signatureComponents.s, signatureComponents.v)) 
            returns (bytes4 magicValue) {
            isValidSignatureNow = magicValue == IERC1271.isValidSignature.selector;
        } catch {}

        if (!isValidSignatureNow) {
            revert PaymentProcessor__EIP1271SignatureInvalid();
        }
    }
}