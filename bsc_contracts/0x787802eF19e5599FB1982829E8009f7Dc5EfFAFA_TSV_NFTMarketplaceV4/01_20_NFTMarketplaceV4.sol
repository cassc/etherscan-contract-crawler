/// @title NFT Marketplace V4
/// @notice contracts/NFTMarketplaceV4.sol
// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IPriceFeed {
    function isTokenAvailable(address) external view returns(bool);
    function getPrice(address tokenAddress) external view returns(uint256);
}


/// @notice Market item struct contains all the details about NFT.
struct MarketItemMetadata {
    /// @param marketItemId: The id of the market item.
    uint256 marketItemId;
    /// @param tokenId: The token id of the NFT.
    uint256 tokenId;
    /// @param seller: The seller of the nft.
    address payable seller;
    /// @param buyer: The buyer of the nft.
    address buyer;
    /// @param price: The marketItem id of the contract.
    uint256 price;
    /// @param listedAt: The timestamp when market item created.
    uint256 listedAt;
    /// @param lockInMonths: The number of months to hold.
    uint256 lockInMonths;
    /// @param unlockAt: The timestamp when the lock-in-period is going to end.
    uint256 unlockAt;
    /// @param onAuction: The boolean value if the NFT is on auction.
    bool onAuction;
    /// @param auctionId: The auction id if the nft is on auction.
    uint256 auctionId;
    /// @param paymentAddress: The paymentAddress of the nft.
    address paymentAddress;
    /// @param isTokenMinted: The boolean value if the token minted or issued.
    bool isTokenMinted;
    /// @param payer: The walletaddress from whom the tokens deducted.
    address payer;
}

contract TSV_NFTMarketplaceV4 is
    Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable,
    PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /// @notice Keep tracking the tokenIds.
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @notice Keep tracking the tokenIds.
    CountersUpgradeable.Counter private _itemIdCounter;

    /// @notice Keep tracking the paymentIds.
    CountersUpgradeable.Counter private _paymentIdCounter;

    /// @notice Mapping between tokenId to their Metadata.
    mapping (uint256 => MarketItemMetadata) public marketItemByTokenId;

    /// @notice Mapping between noOfMonths to bool.
    mapping (uint256 => bool) public isNoOfMonthsAvailable;

    /// @notice Mapping between paymentId to priceFeedAddress.
    mapping (uint256 => address) public paymentIdToTokenAddress;

    /// @notice Mapping between paymentTokenAddress to bool.
    mapping (address => bool) public isTokenAvailable;

    /// @notice Keep track of the refundFeePercentage.
    address public priceFeedAddress;

    /// @notice Keep track of the refundFeePercentage.
    uint256 public refundFeePercentage;

    /// @notice Keep track of the refundDays available.
    uint256 public refundDays;

    /// @notice Keep track month in seconds.
    uint256 private _monthInSeconds;

    /// @notice Mapping between paymentTokenAddress to bool.
    mapping (address => bool) private _isTokenAddedBefore;

    /// @notice Setting the manager.
    mapping (address => bool) public isTokenIssuer;
    mapping (address => bool) public isManager;

    /**
     * @notice Event to keep track when the refund fee percentage updated.
     * @param oldPercentage: The old refund fee percentage.
     * @param newPercentage: The new refund fee percentage.
     */
    event RefundFeePercentageUpdated(
        uint256 oldPercentage,
        uint256 newPercentage
    );

    /**
     * @notice Event to keep track when the token issuer added.
     * @param managerAddress: The old refund fee percentage.
     */
    event ManagerAdded(
        address managerAddress
    );

     /**
     * @notice Event to keep track when the token issuer removed.
     * @param managerAddress: The old refund fee percentage.
     */
    event ManagerRemoved(
        address managerAddress
    );

    /**
     * @notice Event to keep track when the noOfMonths added.
     * @param noOfMonths: The no of months user have to hold.
     */
    event NoOfMonthsAdded(
        uint256 noOfMonths
    );

    /**
     * @notice Event to keep track when the noOfMonths removed.
     * @param noOfMonths: The no of months user have to hold.
     */
    event NoOfMonthsRemoved(
        uint256 noOfMonths
    );

    /**
     * @notice Event to keep track when the refund days updated.
     * @param oldDays: The old refund fee Days.
     * @param newDays: The new refund fee Days.
     */
    event RefundDaysUpdated(
        uint256 oldDays,
        uint256 newDays
    );

    /**
     * @notice Event to keep track when the token added.
     * @param tokenAddress: The new token address.
     */
    event TokenAddedForPayment(
        address tokenAddress
    );

    /**
     * @notice Event to keep track when the token added.
     * @param tokenAddress: The new token address.
     */
    event TokenRemovedForPayment(
        address tokenAddress
    );

    /**
     * @notice Event to keep track when the NFT minted from owner account to another account.
     * @param tokenId: The new tokenId.
     * @param to: The address to whom token minted.
     * @param price: The price in dollars.
     */
    event TokenMintedToAddress(
        uint256 tokenId,
        address to,
        uint256 price
    );

    /**
     * @notice Event to keep track when the NFT issued from owner account to another account.
     * @param tokenId: The new tokenId.
     * @param to: The address to whom token minted.
     * @param price: The price in dollars.
     */
    event TokenIssuedToAddress(
        uint256 tokenId,
        address to,
        uint256 price
    );

    /**
     * @notice Event to keep track when the NFT refunded by buyer.
     * @param tokenId: The new tokenId.
     * @param buyer: The address to whom token minted.
     * @param price: The price in dollars.
     */
    event TokenRefunded(
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    /**
     * @notice Event to keep track when the NFT listed by buyer.
     * @param tokenId: The new tokenId.
     * @param buyer: The address to whom token minted.
     * @param price: The price in dollars.
     */
    event TokenListed(
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    /**
     * @notice Event to keep track when the NFT bought by buyer.
     * @param tokenId: The new tokenId.
     * @param buyer: The address to whom token minted.
     * @param price: The price in dollars.
     */
    event TokenBought(
        uint256 tokenId,
        address buyer,
        uint256 price
    );

    /**
     * @notice Event to keep track when the NFT holding period updated.
     * @param tokenId: The new tokenId.
     * @param noOfMonths: The new no of months.
     */
    event TokenHoldingPeriodUpdated(
        uint256 tokenId,
        uint256 noOfMonths
    );

    /**
     * @notice Initialize function to initialize the default values.
     * @dev Initializing the ERC721 contract with URI Storage.
     * Also initializing the Pauseable nad Ownable Contracts.
     */
    function initialize(address _priceFeedAddress) public initializer {
        __ERC721_init("The Soilverse", "TSV");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();

        /// @notice Setting the refund fee percentage.
        refundFeePercentage = 10;

        /// @notice Setting the month in seconds.
        _monthInSeconds = 2628002;

        /// @notice Setting the isNoOfMonths available.
        isNoOfMonthsAvailable[18] = true;
        isNoOfMonthsAvailable[30] = true;

        /// @notice setting the Price feed address.
        priceFeedAddress = _priceFeedAddress;

        /// @notice setting the initial refund days.
        refundDays = 7;

        /// @notice setting `isManager` as contract owner initial position.
        isManager[owner()] = true;
    }

    /**
     * @notice Pausing the contract.
     * @dev Pausing the contract. Only owner can call.
     * Requirements:
     *  - Contract should be unpaused.
     */
    function pause() external whenNotPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        _pause();
    }

    /**
     * @notice Unpausing the contract.
     * @dev Unpausing the contract.Only owner can call.
     * Requirements:
     *  - Contract should be paused.
     */
    function unpause() external whenPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        _unpause();
    }

    /**
     * @notice Adding the tokenIssuer.
     * Who have the permission to mint & issue tokens to address.
     * @param managerWalletAddress: The issuer wallet address.
     */
    function addManager(address managerWalletAddress) external whenNotPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(managerWalletAddress != address(0), 'Manager Address should not be zero.');

        /// @notice Updating the Manager mapping.
        isManager[managerWalletAddress] = true;

        /// @notice Emitting event.
        emit ManagerAdded(managerWalletAddress);
    }

    /**
     * @notice Removing the Manager.
     * Who have the permission to mint & issue tokens to address.
     * @param managerWalletAddress: The Manager wallet address.
     */
    function removeManager(address managerWalletAddress) external whenNotPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(managerWalletAddress != address(0), 'Manager Address should not be zero.');
        require(isManager[managerWalletAddress], 'Manager Address not available.');

        /// @notice Updating the Manager mapping.
        isManager[managerWalletAddress] = false;

        /// @notice Emitting event.
        emit ManagerRemoved(managerWalletAddress);
    }

    /**
     * @notice Getting total number of payments available.
     */
    function totalPaymentIds() external view returns(uint256) {
        return _paymentIdCounter.current();
    }

    /**
     * @notice Setting the refund fee percentage
     * @param newFeePercentage: the new percentage.
     */
    function setRefundFeePercentage(uint256 newFeePercentage)
        external nonReentrant whenNotPaused {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(
            newFeePercentage <= 100,
            "Percentage should not be more than 100."
        );
        require(
            refundFeePercentage != newFeePercentage,
            "New percentage is same as before."
        );

        /// @notice Tracking the old fee.
        uint256 oldFeePercentage = refundFeePercentage;

        /// @notice Updating the percentage.
        refundFeePercentage = newFeePercentage;

        /// @notice Emitting event.
        emit RefundFeePercentageUpdated(oldFeePercentage, newFeePercentage);
    }

    /**
     * @notice Setting the refund days.
     * @param newRefundDays: the new percentage.
     */
    function setRefundDays(uint256 newRefundDays)
        external nonReentrant whenNotPaused {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(
            newRefundDays > 0,
            "New refund days should be more than zero."
        );
        require(
            refundDays != newRefundDays,
            "Refund days is same as before."
        );

        /// @notice Tracking the old days.
        uint256 oldDays = refundDays;

        /// @notice Updating the percentage.
        refundDays = newRefundDays;

        /// @notice Emitting event.
        emit RefundDaysUpdated(oldDays, newRefundDays);
    }

    /**
     * @notice Setting the new ERC20 token address.
     * @param tokenAddress: the new ERC20 tokenAddress.
     */
    function addERC20TokenForPayment(address tokenAddress)
        external nonReentrant whenNotPaused {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(
            tokenAddress != address(0),
            "Token Address should not be zero."
        );
        require(
            !isTokenAvailable[tokenAddress],
            "Already accepting this token."
        );

        if(!_isTokenAddedBefore[tokenAddress]){
            uint256 paymentId = _paymentIdCounter.current();
            _paymentIdCounter.increment();
            paymentIdToTokenAddress[paymentId] = tokenAddress;
            _isTokenAddedBefore[tokenAddress] = true;
        }

        /// @notice Updating the state.
        isTokenAvailable[tokenAddress] = true;

        /// @notice Emitting event.
        emit TokenAddedForPayment(tokenAddress);
    }

    /**
     * @notice Setting the new ERC20 token address.
     * @param paymentId: the new ERC20 tokenAddress.
     */
    function removeERC20TokenForPayment(uint256 paymentId)
        external nonReentrant whenNotPaused {
        /// @notice Requirements
        _requireOwner(msg.sender);
        address tokenAddress = paymentIdToTokenAddress[paymentId];

        require(
            tokenAddress != address(0),
            "Token Address already zero."
        );
        require(
            isTokenAvailable[tokenAddress],
            "Token is not accepting."
        );

        /// @notice Updating the state.
        isTokenAvailable[tokenAddress] = false;

        /// @notice Emitting event.
        emit TokenRemovedForPayment(tokenAddress);
    }

    /**
     * @notice Minting NFT to a buyer.
     * @param payer: The payer address from whom the token will deduct.
     * @param to: The next owner address.
     * @param uri: The token URL.
     * @param priceInWei: The token price in dollars.
     * @param paymentId: The payment mode.
     */
    function mintNFTToAddressWithFixedPrice (
        address payer,
        address to,
        string calldata uri,
        uint256 priceInWei,
        uint256 noOfMonths,
        uint256 paymentId
    ) external nonReentrant whenNotPaused {
        address tokenAddress = paymentIdToTokenAddress[paymentId];

        /// @notice Requirements.
        _requireManager(msg.sender);
        require(to != address(0), "New owner address should not be zero.");
        require(payer != address(0), "Payer should not be zero.");
        require(priceInWei > 0, "Dollars should not be zero.");
        require(isNoOfMonthsAvailable[noOfMonths], "No of months not available.");
        require(isTokenAvailable[tokenAddress], "Token is not currently accepting.");
        require(
            IPriceFeed(priceFeedAddress).isTokenAvailable(tokenAddress),
            "Token have no price right now."
        );

        uint256 tokenPrice = IPriceFeed(priceFeedAddress).getPrice(tokenAddress);
        uint256 tokenToReceive = getTokenAmount(priceInWei, tokenPrice);

        require(
            IERC20Upgradeable(tokenAddress).transferFrom(payer, address(this), tokenToReceive),
            "ERC20 transfer failed."
        );

        /// @notice Getting the tokenId and MarketItemId.
        uint256 tokenId = _tokenIdCounter.current();
        uint256 itemId = _itemIdCounter.current();

        /// @notice Incrementing the tokenId and MarketItemId.
        _tokenIdCounter.increment();
        _itemIdCounter.increment();

        /// @notice Minting and setting the tokenURI.
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        /// @notice Updating the marketItemMetadata.
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];
        marketItemMetadata.tokenId = tokenId;
        marketItemMetadata.marketItemId = itemId;
        marketItemMetadata.seller = payable(owner());
        marketItemMetadata.buyer = to;
        marketItemMetadata.price = priceInWei;
        marketItemMetadata.listedAt = block.timestamp;
        marketItemMetadata.lockInMonths = noOfMonths;
        marketItemMetadata.unlockAt = block.timestamp + (noOfMonths * _monthInSeconds);
        marketItemMetadata.paymentAddress = tokenAddress;
        marketItemMetadata.isTokenMinted = true;
        marketItemMetadata.payer = payer;

        /// @notice Emitting the event.
        emit TokenMintedToAddress(tokenId, to, priceInWei);
    }

    /**
     * @notice Minting NFT to a buyer.
     * @param to: The next owner address.
     * @param uri: The token URL.
     * @param priceInWei: The token price in wei.
     * @param paymentId: The payment mode.
     */
    function issueNFTToAddressWithFixedPrice (
        address to,
        string calldata uri,
        uint256 priceInWei,
        uint256 noOfMonths,
        uint256 paymentId
    ) external nonReentrant whenNotPaused {
        address tokenAddress = paymentIdToTokenAddress[paymentId];

        /// @notice Requirements.
        _requireManager(msg.sender);
        require(to != address(0), "Address should not be zero.");
        require(priceInWei > 0, "Dollars should not be zero.");
        require(isNoOfMonthsAvailable[noOfMonths], "No of months not available.");
        require(isTokenAvailable[tokenAddress], "Token is not currently accepting.");
        require(
            IPriceFeed(priceFeedAddress).isTokenAvailable(tokenAddress),
            "Token have no price right now."
        );

        /// @notice Getting the tokenId and MarketItemId.
        uint256 tokenId = _tokenIdCounter.current();
        uint256 itemId = _itemIdCounter.current();

        /// @notice Incrementing the tokenId and MarketItemId.
        _tokenIdCounter.increment();
        _itemIdCounter.increment();

        /// @notice Minting and setting the tokenURI.
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        /// @notice Updating the marketItemMetadata.
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];
        marketItemMetadata.tokenId = tokenId;
        marketItemMetadata.marketItemId = itemId;
        marketItemMetadata.seller = payable(owner());
        marketItemMetadata.buyer = to;
        marketItemMetadata.price = priceInWei;
        marketItemMetadata.listedAt = block.timestamp;
        marketItemMetadata.lockInMonths = noOfMonths;
        marketItemMetadata.unlockAt = block.timestamp + (noOfMonths * _monthInSeconds);
        marketItemMetadata.paymentAddress = tokenAddress;
        marketItemMetadata.isTokenMinted = false;

        /// @notice Emiting the event.
        emit TokenIssuedToAddress(tokenId, to, priceInWei);
    }

    /**
     * @notice Function to update holding period.
     * @param tokenId: The tokenId user wants to update the holding period.
     * @param noOfMonths: The new number of months user wants to update.
     */
    function updateHoldingPeriod(
        uint256 tokenId,
        uint256 noOfMonths
        ) external nonReentrant whenNotPaused {
       /// @notice Requirements.
        _requireManager(msg.sender);
        require(_exists(tokenId), "TokenId does not exists.");
        require(isNoOfMonthsAvailable[noOfMonths], "No of months not available.");
        require(marketItemByTokenId[tokenId].lockInMonths != noOfMonths, "New months should not be equal to current holding months.");


        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];
        marketItemMetadata.lockInMonths = noOfMonths;
        marketItemMetadata.unlockAt = marketItemMetadata.listedAt + (noOfMonths * _monthInSeconds);


        /// @notice Emitting the event.
        emit TokenHoldingPeriodUpdated(tokenId, noOfMonths);
    }

    /**
     * @notice Function to refund before refund date.
     * @param tokenId: The token Id buyer wants to refund within refund days.
     */
    function refundNFT(uint256 tokenId) external nonReentrant whenNotPaused {
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];

        /// @notice Requirements.
        require(_exists(tokenId), "TokenId does not exists.");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this tokenId.");
        require(marketItemMetadata.seller == owner(), "Seller is not the owner of the contract.");
        require(marketItemMetadata.isTokenMinted, "Your token is issued to you for that you cannot refund.");
        require(marketItemMetadata.unlockAt > block.timestamp, "Your token is already passed the holding months.");
        require((marketItemMetadata.listedAt + (refundDays * 86400)) >= block.timestamp, "You cannot refund anymore.");
        require(marketItemMetadata.buyer == msg.sender, "You are not the buyer of this tokenId.");
        require(marketItemMetadata.tokenId == tokenId, "TokenId not matched with marketItem.");
        
        /// @notice Tracking the seller.
        address seller = marketItemMetadata.seller;

        /// @notice Tracking the buyer.
        address buyer = marketItemMetadata.buyer;

        /// @notice Tracking the tokenAddress & price from market item.
        address tokenAddress = marketItemMetadata.paymentAddress;
        uint256 priceInWei = marketItemMetadata.price;

        uint256 tokenPrice = IPriceFeed(priceFeedAddress).getPrice(tokenAddress);
        uint256 tokens = getTokenAmount(priceInWei, tokenPrice);
        uint256 tokenToSentToOwner = (tokens * refundFeePercentage) / 100;
        uint256 tokenToSentToBuyer = tokens - tokenToSentToOwner;

        /// @notice Updating the marketItem.
        marketItemMetadata.buyer = address(0);
        
        /// @notice Transferring the ERC20 token to buyer.
        require(
            IERC20Upgradeable(tokenAddress).transfer(buyer, tokenToSentToBuyer),
            "ERC20 transfer failed to buyer."
        );

        /// @notice Transferring the ERC20 token to owner.
        require(
            IERC20Upgradeable(tokenAddress).transfer(owner(), tokenToSentToOwner),
            "ERC20 transfer failed to owner."
        );

        /// @notice refund the nft.
        transferFrom(msg.sender, seller, tokenId);

        /// @notice Emitting the event.
        emit TokenRefunded(tokenId, buyer, priceInWei);
    }

    /**
     * @notice List NFT after holding period.
     * @param tokenId: The token Id which buyer wants to list in market.
     * @param priceInWei: The dollar price of the token.
     */
    function listNFT(uint256 tokenId, uint priceInWei) external whenNotPaused nonReentrant {
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];

        /// @notice Requirements.
        require(_exists(tokenId), "TokenId does not exists.");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this tokenId.");
        require(marketItemMetadata.tokenId == tokenId, "TokenId not matched with marketItem.");
        require(marketItemMetadata.buyer == msg.sender, "You are not the buyer of this tokenId.");
        if(marketItemMetadata.seller == owner()){
            require(marketItemMetadata.unlockAt <= block.timestamp, "Your token is in the holding months.");
            require(marketItemMetadata.lockInMonths > 0, "No of Months is zero.");
            require(marketItemMetadata.paymentAddress != address(0), "Payment address is zero address.");
        }else {
            require(marketItemMetadata.unlockAt == 0, "Unlock month is not zero.");
            require(marketItemMetadata.lockInMonths == 0, "Lock in months is not zero.");
            require(marketItemMetadata.paymentAddress == address(0), "Payment address is not zero address.");
        }

        /// @notice refund the nft.
        transferFrom(msg.sender, address(this), tokenId);

        /// @notice Updating the marketItemMetadata.
        marketItemMetadata.seller = payable(msg.sender);
        marketItemMetadata.buyer = address(0);
        marketItemMetadata.price = priceInWei;
        marketItemMetadata.paymentAddress = address(0);
        marketItemMetadata.unlockAt = 0;
        marketItemMetadata.lockInMonths = 0;

        /// @notice Emitting the event.
        emit TokenListed(tokenId, msg.sender, priceInWei);
    }

    /**
     * @notice Buying listed NFT after holding period.
     * @param tokenId: The token Id which buyer wants to list in market.
     */
    function buyNFT(uint256 tokenId, uint paymentId) external whenNotPaused nonReentrant {
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];
        address tokenAddress = paymentIdToTokenAddress[paymentId];

        /// @notice Requirements.
        require(_exists(tokenId), "TokenId does not exists.");
        require(ownerOf(tokenId) == address(this), "Contract is not the owner of this tokenId.");
        require(isTokenAvailable[tokenAddress], "Token is not currently accepting.");
        require(
            IPriceFeed(priceFeedAddress).isTokenAvailable(tokenAddress),
            "Token have no price right now."
        );
        require(marketItemMetadata.tokenId == tokenId, "TokenId not matched with marketItem.");
        require(marketItemMetadata.buyer == address(0), "Buyer address is not zero.");
        require(marketItemMetadata.seller != address(0), "Seller address is zero.");
        require(marketItemMetadata.unlockAt == 0, "Unlock month is not zero.");
        require(marketItemMetadata.lockInMonths == 0, "Lock in months is not zero.");
        require(marketItemMetadata.paymentAddress == address(0), "Payment address is not zero address.");
        
        /// @notice Tracking the seller address.
        address seller = marketItemMetadata.seller;

        /// @notice Updating the marketItemMetadata.
        marketItemMetadata.buyer = msg.sender;
        marketItemMetadata.seller = payable(address(0));

        /// @notice Tracking the tokenAddress & price from market item.
        uint256 priceInWei = marketItemMetadata.price;

        uint256 tokenPrice = IPriceFeed(priceFeedAddress).getPrice(tokenAddress);
        uint256 tokenToSent = getTokenAmount(priceInWei, tokenPrice);
        
        /// @notice Transferring the ERC20 token to buyer.
        require(
            IERC20Upgradeable(tokenAddress).transferFrom(msg.sender, address(this), tokenToSent),
            "ERC20 transfer failed."
        );
        require(
            IERC20Upgradeable(tokenAddress).transfer(seller, tokenToSent),
            "ERC20 transfer failed."
        );

        /// @notice refund the nft.
        _approve(msg.sender, tokenId);
        transferFrom(address(this), msg.sender, tokenId);

        /// @notice Emitting the event.
        emit TokenBought(tokenId, msg.sender, marketItemMetadata.price);
        
    }

    /**
     * @notice Helper function for checking if the call is owner.
     * @param sender: The caller address.
     */
    function _requireOwner(address sender) private view {
        require(sender == owner(), "Only Owner can call.");
    }

    /**
     * @notice Helper function for checking if the call is tokenIssuer.
     * @param sender: The caller address.
     */
    function _requireManager(address sender) private view {
        require(isManager[sender], "Only manager can call.");
    }

    /**
     * @notice Calculating the token amount based on price & dollar.
     */
    function getTokenAmount(uint256 investPriceInWei, uint256 tokenPriceInWei) public pure returns(uint256) {
        uint256 result = (investPriceInWei * (10 ** 18))/ tokenPriceInWei;
        return result;
    }

    /**
     * @notice Adding the noOfMonths holding period.
     * @param noOfMonths: The no of months user have to hold the NFT.
     */
    function addNoOfMonthsForHolding(uint256 noOfMonths) external whenNotPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(noOfMonths > 0, "No of months should not be zero.");
        require(!isNoOfMonthsAvailable[noOfMonths], "No of months already available.");

        /// @notice Updating the isNoOfMonthsAvailable mapping.
        isNoOfMonthsAvailable[noOfMonths] = true;

        /// @notice Emitting event.
        emit NoOfMonthsAdded(noOfMonths);
    }

    /**
     * @notice Removing the noOfMonths holding period.
     * @param noOfMonths: The no of months user have to hold the NFT.
     */
    function removeNoOfMonthsForHolding(uint256 noOfMonths) external whenNotPaused nonReentrant {
        /// @notice Requirements
        _requireOwner(msg.sender);
        require(noOfMonths > 0, "No of months should not be zero.");
        require(isNoOfMonthsAvailable[noOfMonths], "No of months is not available.");

        /// @notice Updating the isNoOfMonthsAvailable mapping.
        isNoOfMonthsAvailable[noOfMonths] = false;

        /// @notice Emitting event.
        emit NoOfMonthsRemoved(noOfMonths);
    }

    /**
     * @notice Transferring ERC20 tokens available in the contract.
     * @param tokenAddress: The ERC20 token address.
     * @param to: The wallet address to whom will send the tokens.
     * @param amount: The token amount wants to sent.
     */
    function transferERC20Token(
        address tokenAddress,
        address to,
        uint256 amount
    ) external whenNotPaused nonReentrant {
        /// @notice Requirements.
        _requireOwner(msg.sender);
        require(
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= amount,
            "Contract has not enough balance."
        );

        IERC20Upgradeable(tokenAddress).transfer(to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        MarketItemMetadata storage marketItemMetadata = marketItemByTokenId[tokenId];
        require(
            marketItemMetadata.unlockAt < block.timestamp ||
            marketItemMetadata.buyer == address(0),
            "You cannot transfer your NFT till the holiding period."
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}