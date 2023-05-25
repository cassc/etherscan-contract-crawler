// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";
import {OfferTypes} from "./libraries/OfferTypes.sol";
import {ListingTypes} from "./libraries/ListingTypes.sol";
import {SignatureValidator} from "./libraries/SignatureValidator.sol";
import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IExecutionManager} from "./interfaces/IExecutionManager.sol";
import {IExecutionStrategy} from "./interfaces/IExecutionStrategy.sol";

contract VenusMarketplace is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    using OfferTypes for OfferTypes.Offer;
    using OfferTypes for OfferTypes.ItemSeller;
    using ListingTypes for ListingTypes.Listing;
    using ListingTypes for ListingTypes.ItemBuyer;

    address public immutable WETH;
    bytes32 public immutable DOMAIN_SEPARATOR;

    ITransferSelectorNFT public transferSelectorNFT;
    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;

    mapping(address => uint256) public userMinListingNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserListingNonceExecutedOrCancelled;

    mapping(address => uint256) public userMinOfferNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOfferNonceExecutedOrCancelled;

    event CancelListing(address indexed seller, uint256 indexed oldNonce, uint256 indexed newNonce);
    event CancelMultipleListings(address indexed seller, uint256[] nonces);

    event CancelOffer(address indexed seller, uint256 indexed oldNonce, uint256 indexed newNonce);
    event CancelMultipleOffers(address indexed buyer, uint256[] nonces);

    event ListingMaker(
        bytes32 listingHash,
        uint256 listingNonce,
        address indexed seller,
        address indexed buyer,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    );

    event OfferMaker(
        bytes32 offerHash,
        uint256 offerNonce,
        address indexed seller,
        address indexed buyer,
        address indexed strategy,
        address currency,
        address collection,
        uint256 tokenId,
        uint256 price,
        uint256 amount
    );

    event NewCurrencyManager(address indexed currencyManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);
    event NewExecutionManager(address indexed executionManager);

    constructor(address _currencyManager, address _executionManager, address _WETH) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("VenusMarketplace"),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        WETH = _WETH;
    }

    function cancelAllListingsForSender(uint256 newNonce) external {
        require(newNonce > userMinListingNonce[msg.sender], "Cancel: nonce lower than current");
        require(newNonce < userMinListingNonce[msg.sender] + 500000, "Cancel: cannot cancel more listings");
        uint256 oldNonce = userMinListingNonce[msg.sender];
        userMinListingNonce[msg.sender] = newNonce;
        emit CancelListing(msg.sender, oldNonce, newNonce);
    }

    function cancelMultipleListingsForSender(uint256[] calldata nonces) external {
        require(nonces.length > 0, "Cancel: cannot be empty");
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] >= userMinListingNonce[msg.sender], "Cancel: listing nonce lower than current");
            _isUserListingNonceExecutedOrCancelled[msg.sender][nonces[i]] = true;
        }
        emit CancelMultipleListings(msg.sender, nonces);
    }

    function cancelAllOffersForSender(uint256 newNonce) external {
        require(newNonce > userMinOfferNonce[msg.sender], "Cancel: nonce lower than current");
        require(newNonce < userMinOfferNonce[msg.sender] + 500000, "Cancel: cannot cancel more offers");
        uint256 oldNonce = userMinOfferNonce[msg.sender];
        userMinOfferNonce[msg.sender] = newNonce;
        emit CancelOffer(msg.sender, oldNonce, newNonce);
    }

    function cancelMultipleOffersForSender(uint256[] calldata nonces) external {
        require(nonces.length > 0, "Cancel: cannot be empty");
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] >= userMinOfferNonce[msg.sender], "Cancel: offer nonce lower than current");
            _isUserOfferNonceExecutedOrCancelled[msg.sender][nonces[i]] = true;
        }
        emit CancelMultipleOffers(msg.sender, nonces);
    }

    /**
     * @dev If a user wants to sell a NFT, they're creating a listing.
     *      When a buyer wants to buy a NFT now, it approves the owner listing.
     * @param listing Listing object
     * @param itemBuyer Item buyer object
     */
    function buyWithWETH(
        ListingTypes.Listing calldata listing,
        ListingTypes.ItemBuyer calldata itemBuyer
    ) external nonReentrant {
        require(msg.sender == itemBuyer.buyer, "Not buyer");

        bytes32 listingHash = listing.hash();
        _validateListing(listing, listingHash);

        (bool isBuyValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(listing.strategy).canBuy(
            listing, itemBuyer
        );
        require(isBuyValid, "Strategy: cannot buy");

        _isUserListingNonceExecutedOrCancelled[listing.seller][listing.nonce] = true;

        _transferFunds(listing.seller, itemBuyer.buyer, listing.currency, listing.price);
        _transferNonFungibleToken(listing.collection, listing.seller, itemBuyer.buyer, tokenId, amount);

        emit ListingMaker(
            listingHash,
            listing.nonce,
            listing.seller,
            itemBuyer.buyer,
            listing.strategy,
            listing.currency,
            listing.collection,
            tokenId,
            listing.price,
            amount
        );
    }

    /**
     * @dev If a user wants to sell a NFT, they're creating a listing.
     *      When a buyer wants to buy a NFT now, it approves the owner listing. (pays with ETH)
     * @param listing Listing object
     * @param itemBuyer Item buyer object
     */
    function buyWithETH(
        ListingTypes.Listing calldata listing,
        ListingTypes.ItemBuyer calldata itemBuyer
    ) external payable nonReentrant {
        require(listing.currency == WETH, "Not WETH");
        require(msg.sender == itemBuyer.buyer, "Not buyer");

        if (listing.price > msg.value) {
            IERC20(WETH).safeTransferFrom(msg.sender, address(this), listing.price - msg.value);
        } else {
            require(listing.price == msg.value, "Offer: msg.value too high");
        }

        // Wrap ETH sent to this contract
        IWETH(WETH).deposit{value: msg.value}();

        bytes32 listingHash = listing.hash();
        _validateListing(listing, listingHash);

        (bool isBuyValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(listing.strategy).canBuy(
            listing, itemBuyer
        );
        require(isBuyValid, "Strategy: cannot buy");

        _isUserListingNonceExecutedOrCancelled[listing.seller][listing.nonce] = true;

        _transferWethFunds(listing.seller, listing.price);
        _transferNonFungibleToken(listing.collection, listing.seller, itemBuyer.buyer, tokenId, amount);

        emit ListingMaker(
            listingHash,
            listing.nonce,
            listing.seller,
            itemBuyer.buyer,
            listing.strategy,
            listing.currency,
            listing.collection,
            tokenId,
            listing.price,
            amount
        );
    }

    /**
     * @dev If a user wants to buy a NFT with a different price, they're creating an offer.
     *      If the seller approves the offer, the NFT is transferred to the buyer.
     * @param offer Offer object
     * @param itemSeller Item seller object
     */
    function sellWithWETH(
        OfferTypes.Offer calldata offer,
        OfferTypes.ItemSeller calldata itemSeller
    ) external nonReentrant {
        require(msg.sender == itemSeller.seller, "Not seller");

        bytes32 offerHash = offer.hash();
        _validateOffer(offer, offerHash);

        (bool isSaleValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(offer.strategy).canSell(
            offer, itemSeller
        );
        require(isSaleValid, "Strategy: cannot sell");

        _isUserOfferNonceExecutedOrCancelled[offer.buyer][offer.nonce] = true;

        _transferFunds(itemSeller.seller, offer.buyer, offer.currency, offer.price);
        _transferNonFungibleToken(offer.collection, itemSeller.seller, offer.buyer, tokenId, amount);

        emit OfferMaker(
            offerHash,
            offer.nonce,
            itemSeller.seller,
            offer.buyer,
            offer.strategy,
            offer.currency,
            offer.collection,
            tokenId,
            offer.price,
            amount
        );
    }

    // Validators
    function _validateOffer(OfferTypes.Offer calldata offer, bytes32 offerHash) internal view {
        // Verify whether order nonce has expired
        bool isNonceValid = !_isUserOfferNonceExecutedOrCancelled[offer.buyer][offer.nonce];
        bool isNonceBiggerThanMin = offer.nonce >= userMinOfferNonce[offer.buyer];
        require(isNonceValid && isNonceBiggerThanMin, "Offer: matching offer expired");

        // Verify the signer is not address(0)
        require(offer.buyer != address(0), "Invalid signer");

        // Verify the price is not 0
        require(offer.price > 0, "Invalid price");

        // Verify amount is not 0
        require(offer.amount > 0, "Invalid amount");

        // Verify the validity of the signature
        require(
            SignatureValidator.verify(offerHash, offer.buyer, offer.signature, DOMAIN_SEPARATOR),
            "Signature: invalid"
        );

        // Verify if the currency is supported
        require(currencyManager.isCurrencyWhitelisted(offer.currency), "Currency: Not exists");

        // Verify if the strategy is supported
        require(executionManager.isStrategyWhitelisted(offer.strategy), "Strategy: Not exists");
    }

    function _validateListing(ListingTypes.Listing calldata listing, bytes32 listingHash) internal view {
        // Verify whether order nonce has expired
        bool isNonceValid = !_isUserListingNonceExecutedOrCancelled[listing.seller][listing.nonce];
        bool isNonceBiggerThanMin = listing.nonce >= userMinListingNonce[listing.seller];
        require(isNonceValid && isNonceBiggerThanMin, "Listing: matching listing expired");

        // Verify the signer is not address(0)
        require(listing.seller != address(0), "Invalid signer");

        // Verify the price is not 0
        require(listing.price > 0, "Invalid price");

        // Verify amount is not 0
        require(listing.amount > 0, "Invalid amount");

        // Verify the validity of the signature
        require(
            SignatureValidator.verify(listingHash, listing.seller, listing.signature, DOMAIN_SEPARATOR),
            "Signature: invalid"
        );

        // Verify if the currency is supported
        require(currencyManager.isCurrencyWhitelisted(listing.currency), "Currency: Not exists");

        // Verify if the strategy is supported
        require(executionManager.isStrategyWhitelisted(listing.strategy), "Strategy: Not exists");
    }

    // Setters
    function setTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Owner: cannot be null address");
        transferSelectorNFT = ITransferSelectorNFT(_transferSelectorNFT);
        emit NewTransferSelectorNFT(_transferSelectorNFT);
    }

    function setCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Owner: cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit NewCurrencyManager(_currencyManager);
    }

    function setExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Owner: cannot be null address");
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    // Getters
    function isUserListingNonceExecutedOrCancelled(address seller, uint256 nonce) external view returns (bool) {
        return _isUserListingNonceExecutedOrCancelled[seller][nonce];
    }

    function isUserOfferNonceExecutedOrCancelled(address buyer, uint256 nonce) external view returns (bool) {
        return _isUserOfferNonceExecutedOrCancelled[buyer][nonce];
    }

    // Transfers
    function _transferFunds(address seller, address buyer, address currency, uint256 price) internal {
        IERC20(currency).transferFrom(buyer, seller, price);
    }

    function _transferWethFunds(address seller, uint256 price) internal {
        IERC20(WETH).safeTransfer(seller, price);
    }

    function _transferNonFungibleToken(
        address collection, address seller, address buyer, uint256 tokenId, uint256 amount
    ) internal {
        address transferManager = transferSelectorNFT.getTransferManagerForToken(collection);
        require(transferManager != address(0), "No transfer manager");

        ITransferManagerNFT(transferManager).transferNonFungibleToken(
            collection, seller, buyer, tokenId, amount
        );
    }
}