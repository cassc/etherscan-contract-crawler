// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721URIStorage.sol";
import "Counters.sol";
import "ERC721.sol";
import "ReentrancyGuard.sol";
import "NFTCollection.sol";

contract DeFiBamaMarketPlace is ReentrancyGuard, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _buyNowtokenIds;
    Counters.Counter private _auctiontokenIds;
    Counters.Counter private _numberOfSalesMade;
    Counters.Counter private _numberOfBidsMade;
    Counters.Counter private _numberOfItemsListed;

    uint256 private totalIncome;
    address payable private owner;
    uint256 private listingPrice;
    uint256 private salesPercentage;
    uint256 private minimumBidIncreasePercentage;
    bool private initialized;

    error NotApprovedForMarketplace();

    enum Category {
        Art, Music, Video, Sports, Collectible, Specialised, Photography, Other
    }

    mapping(uint256 => Market) private buyNowNFTs;
    mapping(address => mapping(uint256 => MarketItem)) private buyNowListing;
    mapping(address => mapping(uint256 => AuctionItem)) private auctionListing;
    mapping(uint256 => Auction) private auctionNFTs;

    struct Market {
        MarketItem _marketItem;
        bool _isDeleted;
    }
    struct Auction {
        AuctionItem _auctionItem;
        bool _isDeleted;
    }
    struct NFT {
        address adr;
        uint256 id;
    }

    struct MarketItem {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 price;
        uint8 category;
        NFT nft;
        uint256 profession;
    }

    struct AuctionItem {
        uint256 tokenId;
        address payable owner;
        address payable creator;
        uint256 basePrice;
        uint8 category;
        uint256 currentBidPrice;
        address highestBiderAddress;
        uint256 startTime;
        uint256 auctionDurationBasedOnHours;
        NFT nft;
        uint256 profession;
    }

    event buyNowItemSold(
        address buyerAddress, uint256 price, address oldOwner
    );

    event buyNowMarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint256 price,
        uint8 category
    );

    event AuctionMarketItemCreated (
        uint256 indexed tokenId,
        address owner,
        address creator,
        uint8 category,
        uint256 currentBidPrice,
        address highestBiderAddress,
        uint256 startTime,
        uint256 auctionDurationBasedOnHours
    );

    event ItemRemovedFromSales(
        uint256 id, address nftAddress, uint256 tokenId
    );

    event BidMade(
        address addressOfBidder, uint256 oldPrice, uint256 newPrice
    );

    event LastTimeAuctionChecked(uint256 time);

    modifier isOwner(address addressOfNFT, uint256 tokenId) {
        IERC721 nft = IERC721(addressOfNFT);
        require(msg.sender == nft.ownerOf(tokenId));
        _;
    }

    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        owner = payable(msg.sender);
        salesPercentage = 4;
        totalIncome = 0;
        listingPrice = 0;
        minimumBidIncreasePercentage = 5;
    }

    function removeFromMarketSale(uint256 id) nonReentrant public {
        Market storage m = buyNowNFTs[id];
        require(m._marketItem.owner == msg.sender, "Only owner of the NFT can remove the item from marketplace.");

        // Transfer back the NFT from Marketplace to user
        IERC721 nft = IERC721(m._marketItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(msg.sender), m._marketItem.nft.id);

        // Remove the nft from market
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        m._isDeleted = true;
        emit ItemRemovedFromSales(id, m._marketItem.nft.adr, m._marketItem.nft.id);
    }

    function removeFromAuctionSale(uint256 id) nonReentrant public {
        Auction storage a = auctionNFTs[id];
        require(a._auctionItem.owner == msg.sender, "Only owner of the NFT can remove the item from marketplace.");
        // Only remove if there is no bid for item
        require(a._auctionItem.currentBidPrice == 0, "There is a bid for your item, so cannot be removed from marketplace.");

        // Transfer back the NFT from Marketplace to user
        IERC721 nft = IERC721(a._auctionItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(a._auctionItem.nft.id), payable(msg.sender), a._auctionItem.nft.id);

        // Remove the nft from market
        delete (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id]);
        a._isDeleted = true;
        emit ItemRemovedFromSales(id, a._auctionItem.nft.adr, a._auctionItem.nft.id);
    }

    function makeABid(uint256 id) nonReentrant payable public {
        // Get the NFT based on id
        Auction storage a = auctionNFTs[id];
        require(msg.value >= a._auctionItem.basePrice, "The offer must be greater than base price");

        // Check if the auction is finished or not
        uint256 numberOfHours = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].auctionDurationBasedOnHours * 1 hours;
        uint256 endDate = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].startTime + numberOfHours;
        require(block.timestamp <= endDate, "The auction is closed now.");

        // Check the bid value and make sure it is valid
        uint256 minimumBidAllowed;
        if (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice > 1) {
            minimumBidAllowed = (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice) + ((auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice * minimumBidIncreasePercentage) / 100);
        } else {
            minimumBidAllowed = (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].basePrice) + ((auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].basePrice * minimumBidIncreasePercentage) / 100);
        }
        require(msg.value >= minimumBidAllowed, "The bid must be at least 5% greater than previous bid.");

        // Check if this is the first bid or not, if not give the money of last bidder back
        if (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress != address(0)) {
            payable(auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress).transfer(auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice);
        }
        emit BidMade(msg.sender, auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice, msg.value);
        auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].highestBiderAddress = msg.sender;
        auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id].currentBidPrice = msg.value;
        auctionNFTs[id]._auctionItem = auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id];
    }

    // Check auction and wrap up finished auctions
    function checkAuctions() nonReentrant external payable {
        emit LastTimeAuctionChecked(block.timestamp);
        uint256 currentId = _auctiontokenIds.current();
        Auction[] memory items = new Auction[](currentId);

        // Loop through all items
        for (uint256 i = 0; i < currentId; i++) {
            Auction storage m = auctionNFTs[i];

            // Make sure is not deleted already
            if (m._isDeleted == false) {
                uint256 numberOfHours =  m._auctionItem.auctionDurationBasedOnHours * 1 hours;
                uint256 endDate =  m._auctionItem.startTime + numberOfHours;
                // if time of block is greater than endDate then auction is finished wrap it up!
                if (block.timestamp > endDate) {

                    // check if there is any bid and if there isn't just delete the auction item
                    AuctionItem storage item =  m._auctionItem;
                    if (item.highestBiderAddress != address(0)) {
                        address payable ownerOfNFT = payable(NFTCollection(m._auctionItem.nft.adr).ownerOf(m._auctionItem.nft.id));

                        // Transfer nft to highest bidder
                        IERC721 nft = IERC721(m._auctionItem.nft.adr);
                        nft.safeTransferFrom(nft.ownerOf(m._auctionItem.nft.id), payable(msg.sender), m._auctionItem.nft.id);

                        // Tranfser the money and commission
                        uint256 amountsTobePaidToOwner = (m._auctionItem.currentBidPrice * (100 - salesPercentage)) / 100;
                        uint256 commision = (m._auctionItem.currentBidPrice * salesPercentage) / 100 ;
                        totalIncome += commision;
                        payable(m._auctionItem.owner).transfer(amountsTobePaidToOwner);
                        owner.transfer(commision);
                        m._auctionItem.owner = payable(m._auctionItem.highestBiderAddress);
                    }
                    delete (auctionListing[m._auctionItem.nft.adr][m._auctionItem.nft.id]);
                    m._isDeleted = true;
                    auctionNFTs[i] = m;
                }
            }
        }
    }
    function buyMarketPlaceItem(uint256 id) nonReentrant public payable {
        Market storage m = buyNowNFTs[id];
        require(msg.value >= m._marketItem.price, "Price must be greater than the price set by the owner.");

        // Transfer the NFT
        IERC721 nft = IERC721(m._marketItem.nft.adr);
        nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(msg.sender), m._marketItem.nft.id);

        // Transfer the price and commission
        uint256 adminFees = (msg.value * salesPercentage) / 100;
        owner.transfer(adminFees);
        totalIncome += adminFees;
        uint256 netPrice = (msg.value * (100 - salesPercentage)) / 100;
        payable(m._marketItem.owner).transfer(netPrice);

        // edit the market item
        m._marketItem.owner = payable(msg.sender);
        m._isDeleted = true;

        // remove the nft from market sale
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        // increase stats
        _numberOfSalesMade.increment();

        emit buyNowItemSold(msg.sender, msg.value, m._marketItem.owner);
    }

    function listNFTForSaleOnMarket(uint256 price, address addressOfNFT, uint256 tokenId,
     uint8 category, uint256 prefession) isOwner(addressOfNFT, tokenId) nonReentrant public payable {
        require(category <= 10, "Invalid Category");
        require(msg.value >= listingPrice, "Not enough money for listing");
        require(price > 0, "Price must be greater than zero!");

        // Transfer the nft to marketplace
        IERC721 nftContract = IERC721(addressOfNFT);
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        nftContract.safeTransferFrom(nftContract.ownerOf(tokenId), payable(address(this)), tokenId);

        // Create Market Item for the nft
        MarketItem memory m = MarketItem(tokenId, payable(msg.sender), payable(NFTCollection(addressOfNFT).creator()), price, category, NFT(addressOfNFT, tokenId), prefession);
        buyNowListing[addressOfNFT][tokenId] = m;
        buyNowNFTs[_buyNowtokenIds.current()] = Market(m, false);
        _buyNowtokenIds.increment();
        //emit buyNowMarketItemCreated(tokenId, payable(msg.sender), payable(msg.sender), price, category);
    }

    function listNFTForSaleOnAuction(uint256 price, address addressOfNFT, uint256 tokenId,
     uint8 category, uint auctionDurationInHours, uint256 profession) nonReentrant isOwner(addressOfNFT, tokenId) public payable {
        require(category <= 7, "Invalid Category");
        require(msg.value >= listingPrice, "Invalid Market Type");
        require(price > 0, "Price must be greater than zero!");

        // Transfer the nft to marketplace
        IERC721 nftContract = IERC721(addressOfNFT);
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        nftContract.safeTransferFrom(nftContract.ownerOf(tokenId), payable(address(this)), tokenId);
        // Create the nft and execute listing
        NFT memory nft = NFT(addressOfNFT, tokenId);
        listForAuction(price, category, auctionDurationInHours, nft, profession);
    }

    function listForAuction(uint256 price, uint8 category, uint auctionDurationInHours, NFT memory nft, uint256 prefession) private {
        // Create Auction Item
        AuctionItem memory a = AuctionItem(nft.id, payable(msg.sender), payable(msg.sender), price, category, 0, address(0), block.timestamp, auctionDurationInHours, nft, prefession);
        auctionListing[nft.adr][nft.id] = a;
        auctionNFTs[_auctiontokenIds.current()] = Auction(a, false);
        emit AuctionMarketItemCreated(nft.id, payable(msg.sender), payable(msg.sender), category, price, payable(msg.sender), block.timestamp, auctionDurationInHours);
        _auctiontokenIds.increment();
    }

    // Admin functions
    function deleteAuctionItem(uint256 id) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        Auction storage a = auctionNFTs[id];

        // Transfer back the NFT from Marketplace to user
        // IERC721 nft = IERC721(a._auctionItem.nft.adr);
        // nft.safeTransferFrom(nft.ownerOf(a._auctionItem.nft.id), payable(msg.sender), a._auctionItem.nft.id);

        // Remove the nft from market
        delete (auctionListing[a._auctionItem.nft.adr][a._auctionItem.nft.id]);
        a._isDeleted = true;
        emit ItemRemovedFromSales(id, a._auctionItem.nft.adr, a._auctionItem.nft.id);
    }

    /* delete an auction and return money to bidder if there is any violations */
    function deleteByNowItem(uint256 id) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        Market storage m = buyNowNFTs[id];

        // Transfer back the NFT from Marketplace to user
        // IERC721 nft = IERC721(m._marketItem.nft.adr);
        // nft.safeTransferFrom(nft.ownerOf(m._marketItem.nft.id), payable(owner), m._marketItem.nft.id);

        // Remove the nft from market
        delete (buyNowListing[m._marketItem.nft.adr][m._marketItem.nft.id]);
        m._isDeleted = true;
    }

    /* Updates the listing Percentage of the contract */
    function updateListingPrice(uint256 _price) public nonReentrant {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        listingPrice = _price;
    }

    /* Returns the listing Percentage of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Updates the sales Percentage of the contract */
    function updateSalesPercentage(uint256 _percentage) nonReentrant public {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        salesPercentage = _percentage;
    }

    /* Returns the number of sales on the contract */
    function getNumberOfSalesMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfSalesMade.current();
    }

    /* Returns the number of bides made on the contract */
    function getNumberOfBidsMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfBidsMade.current();
    }

    /* Returns the number of items listed on the contract */
    function getNumberOfItemsListed() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return _numberOfItemsListed.current();
    }

    /* Returns the money made on the contract */
    function getMoneyMade() public view returns(uint256) {
        require(owner == msg.sender, "Only marketplace owner can run this.");
        return totalIncome;
    }

    /* Returns the sales Percentage of the contract */
    function getSalesPercentage() public view returns (uint256) {
        return salesPercentage;
    }

    /* Returns the current id of Buy Now the contract */
    function getCurrentIdOfBuyNowListing() public view returns (uint256) {
        return _buyNowtokenIds.current();
    }

    /* Returns the current id of Auction the contract */
    function getCurrentIdOfAuctionListing() public view returns (uint256) {
        return _auctiontokenIds.current();
    }
    
    /* Updates the bid Percentage of the contract */
    function updateMinimumBidIncreasePercentage(uint256 _percentage) nonReentrant public {
        require(owner == msg.sender, "Only marketplace owner can update listing price.");
        minimumBidIncreasePercentage = _percentage;
    }

    /* Returns the minimum bid increase percentage the contract */
    function getMinimumBidIncreasePercentage() public view returns(uint256) {
        return minimumBidIncreasePercentage;
    }

    // It must be implemenetd so marketplace place can hold nfts
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* Withdraw the remaining money on contract */
    function withdrawBalance() nonReentrant public payable {
        require(msg.sender == owner, "Only Market Place Owner can run this command.");
        owner.transfer(address(this).balance);
    }

    // API Functions
    function getListedItemsOnMarket() public view returns(MarketItem[] memory) {
        uint256 currentId = _buyNowtokenIds.current();
        MarketItem[] memory items = new MarketItem[](currentId);
        for (uint256 i = 0; i < _buyNowtokenIds.current(); i++) {
            Market storage m = buyNowNFTs[i];
            if (m._isDeleted == false) {
                items[i] = m._marketItem;
            }
        }
        return items;
    }

    // API Functions
    function getIdsOfListedItemsOnMarket() public view returns(uint256[] memory) {
        uint256 currentId = _buyNowtokenIds.current();
        uint256[] memory items = new uint256[](currentId);
        for (uint256 i = 0; i < _buyNowtokenIds.current(); i++) {
            Market storage m = buyNowNFTs[i];
            if (m._isDeleted == false) {
                items[i] = i;
            }
        }
        return items;
    }

    function getListedItemsOnAuctions() public view returns(AuctionItem[] memory) {
        uint256 currentId = _auctiontokenIds.current();
        AuctionItem[] memory items = new AuctionItem[](currentId);
        for (uint256 i = 0; i < _auctiontokenIds.current(); i++) {
            Auction storage m = auctionNFTs[i];
            if (m._isDeleted == false) {
                items[i] = m._auctionItem;
            }
        }
        return items;
    }

    function getIdsOfListedItemsOnAuctions() public view returns(uint256[] memory) {
        uint256 currentId = _auctiontokenIds.current();
        uint256[] memory items = new uint256[](currentId);
        for (uint256 i = 0; i < _auctiontokenIds.current(); i++) {
            Auction storage m = auctionNFTs[i];
            if (m._isDeleted == false) {
                items[i] = i;
            }
        }
        return items;
    }

    function getBuyNowId() public view returns(uint256) {
        return _buyNowtokenIds.current();
    }

    function getAuctionId() public view returns(uint256) {
        return _auctiontokenIds.current();
    }
}