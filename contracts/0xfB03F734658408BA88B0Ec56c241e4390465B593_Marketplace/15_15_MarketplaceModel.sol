// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import 'hardhat/console.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract MarketplaceModel is Initializable, PausableUpgradeable, AccessControlUpgradeable {

    /// @dev Store all opened markets
    mapping (address => bool) public markets;
    
    struct Offer {
        bool isForSale;
        uint256 tokenId;
        address seller; 
        uint256 minValue;       // in ether
        address onlySellTo;     // specify to sell only to a specific person
        uint256 lastSellValue;
    }

    struct Bid {
        bool hasBid;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

    /**
     * @dev A record of NFTs that are offered for sale at a specific minimum value, 
     * and perhaps to a specific person, the key to access and offer is the tokenID.
     */
    mapping (address => mapping (uint256 => Offer)) public offeredForSale;

    /// @dev A record of the highest collectible bid, the key to access a bid is the collectibleID
    mapping (address => mapping (uint256 => Bid)) public bids;

    /// @dev Amount of ETH user can withdraw from contract
    mapping (address => uint256) public pendingWithdrawals;

    // EVENTS //

    event CollectibleOffered(address indexed collectibleAddress, uint256 indexed tokenId, uint256 minValue, address indexed toAddress, uint256 lastSellValue);
    event CollectibleBidEntered(address indexed collectibleAddress, uint256 indexed tokenId, uint256 value, address indexed fromAddress);
    event CollectibleBidWithdrawn(address indexed collectibleAddress, uint256 indexed tokenId, uint256 value, address indexed fromAddress);
    event CollectibleBought(address indexed collectibleAddress, uint256 indexed tokenId, uint256 value, address indexed fromAddress, address toAddress);
    event CollectibleNoLongerForSale(address indexed collectibleAddress, uint256 indexed tokenId);

    event CollecltibleMarketSetup(address indexed collectibleAddress, bool indexed setup);

    // MODIFIERS //

    /**
     * @dev Modifier to make a function only callable by the callectible owner
     */
    modifier onlyCollectibleOwner(address collectibleAddress, uint256 tokenId) {
        require(IERC721Upgradeable(collectibleAddress).ownerOf(tokenId) == msg.sender, "You are not collectible Owner");
        _;
    }

    /**
     * @dev Modifier to make a function not callable by the callectible owner
     */
    modifier notCollectibleOwner(address collectibleAddress, uint256 tokenId) {
        require(IERC721Upgradeable(collectibleAddress).ownerOf(tokenId) != msg.sender, "You are the collectible Owner"); // Print is not owned by sender
        _;
    }

    /**
     * @dev Modifier to make a function only callable when market is opened
     */
    modifier marketIsOpen(address collectibleAddress) {
        require(markets[collectibleAddress], "Market for this collectible is closed");
        _;
    }

    // INITIALIZER //
  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _adminAddress) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __Marketplace_init_unchained(_adminAddress);
        
    }

    function __Marketplace_init_unchained(
        address _adminWallet
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        // console.log('granted admin role for', _adminWallet);
    }

    // PUBLIC FUNCTIONS //

    function setupMarket(address collectibleAddress, bool open) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
         require(
            ERC165CheckerUpgradeable.supportsERC165(collectibleAddress), 
            "Provided address doesnt support ERC165 interface and probably not an NFT"
        );
        markets[collectibleAddress] = open;
        
        emit CollecltibleMarketSetup(collectibleAddress, open);

        return true;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // PRIVATE FUNCTIONS //

    function _checkOffer(address collectibleAddress, Offer memory offer, uint256 tokenId) private view returns(bool) {
        require(offer.tokenId >= 0, "Offer tokenId does not exist");
        require(offer.isForSale, "Offer is not for sale");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender, "User cant bought this Collectible");
        require(offer.seller == IERC721Upgradeable(collectibleAddress).ownerOf(tokenId), "Seller is not an Collectible owner");
        return true;
    }

    /**
     * @dev
     * withdrawal from market
     **/

    function _updatePendingWithdrawals(Offer memory offer, uint256 amount) private {
        pendingWithdrawals[offer.seller] += amount;
    }

    /// @dev Kill bid and refund value
    function _refundBuyerBid(address collectibleAddress, Bid memory bid, uint256 tokenId) private returns (bool) {
        pendingWithdrawals[bid.bidder] += bid.value;
        bids[collectibleAddress][tokenId] = Bid(false, tokenId, address(0), 0);

        return true;
    }

    function _makeCollectibleUnavailableToSale(address collectibleAddress, address to, uint256 tokenId, uint256 lastSellValue) private {
        Offer storage offer = offeredForSale[collectibleAddress][tokenId];
        offeredForSale[collectibleAddress][tokenId] = Offer(false, tokenId, offer.seller, 0, to, lastSellValue);
        emit CollectibleNoLongerForSale(collectibleAddress, tokenId);
    }

    // BUYER FUNCTIONS //

    function _buyCollectible(address collectibleAddress, uint256 tokenId, uint256 amount) internal {
        Offer storage offer = offeredForSale[collectibleAddress][tokenId];

        require(amount >= offer.minValue, "Didn't send enough Amount");
        require(_checkOffer(collectibleAddress, offer, tokenId), "Offer is not valid");

        IERC721Upgradeable(collectibleAddress).transferFrom(offer.seller, msg.sender, tokenId);

        _updatePendingWithdrawals(offer, amount);
        _makeCollectibleUnavailableToSale(collectibleAddress, msg.sender, tokenId, amount);
        
        Bid storage bid = bids[collectibleAddress][tokenId]; // get the current bid for that print if any
        
        if (bid.bidder == msg.sender) {
            _refundBuyerBid(collectibleAddress, bid, tokenId); // Check for the case where there is a bid from the new owner and refund it. Any other bid can stay in place.
        }

        emit CollectibleBought(collectibleAddress, tokenId, amount, offer.seller, msg.sender);
    }

    function _enterBidForCollectible(address collectibleAddress, uint256 tokenId, uint256 amount) internal {
        // get the current bid for that print if any
        Bid storage existing = bids[collectibleAddress][tokenId];
        
        // Must outbid previous bid by at least 5%. Apparently is not possible to 
        // multiply by 1.05, that's why we do it manually.
        require(amount >= existing.value + (existing.value * 5 / 100), "Must outbid previous bid by at least 5%");
        
        if (existing.value > 0) {
            // Refund the failing bid from the previous bidder
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        // add the new bid
        bids[collectibleAddress][tokenId] = Bid(true, tokenId, msg.sender, amount);
        
        emit CollectibleBidEntered(collectibleAddress, tokenId, amount, msg.sender);
    }

    function _withdrawBidForCollectible(address collectibleAddress, uint256 tokenId) internal {
        Bid storage bid = bids[collectibleAddress][tokenId]; // get the current bid for that print if any
        
        require(bid.bidder == msg.sender);

        bool sent = _refundBuyerBid(collectibleAddress, bid, tokenId);
        require(sent, "Bid was not withdrawed correctly!");
        
        emit CollectibleBidWithdrawn(collectibleAddress, tokenId, bid.value, msg.sender);
    }

    // SELLER FUNCTIONS //

    function _offerCollectibleForSaleToAddress(address collectibleAddress, uint256 tokenId, uint256 minSalePrice, address toAddress) internal {
        uint256 lastSellValue = offeredForSale[collectibleAddress][tokenId].lastSellValue;
        offeredForSale[collectibleAddress][tokenId] = Offer(true, tokenId, msg.sender, minSalePrice, toAddress, lastSellValue);
        
        emit CollectibleOffered(collectibleAddress, tokenId, minSalePrice, toAddress, lastSellValue);
    }

    function _withdrawOfferForCollectible(address collectibleAddress, uint256 tokenId) internal {
        uint256 lastSellValue = offeredForSale[collectibleAddress][tokenId].lastSellValue;
        offeredForSale[collectibleAddress][tokenId] = Offer(false, tokenId, msg.sender, 0, address(0), lastSellValue);

        emit CollectibleNoLongerForSale(collectibleAddress, tokenId);
    }

    function _acceptBidForCollectible(address collectibleAddress, uint256 tokenId, uint256 minPrice) internal {
        Bid storage bid = bids[collectibleAddress][tokenId];

        require(bid.value > 0, "There is no actual bid");
        require(bid.value >= minPrice, "Bid is withdrawn and replaced with a lower bid");

        IERC721Upgradeable(collectibleAddress).transferFrom(msg.sender, bid.bidder, tokenId);

        Offer storage offer = offeredForSale[collectibleAddress][tokenId];
        
        _updatePendingWithdrawals(offer, bid.value);
        _makeCollectibleUnavailableToSale(collectibleAddress, bid.bidder, tokenId, bid.value);

        emit CollectibleBought(collectibleAddress, tokenId, bid.value, msg.sender, bid.bidder);

        bids[collectibleAddress][tokenId] = Bid(false, tokenId, address(0), 0);
    }

    // WITHDRAW //

    function _withdraw() internal {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Not enought funds for withdraw");

        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;

        bool sent = payable(msg.sender).send(amount);
        require(sent, "ETH was not withdrawn correctly!");
    }
}