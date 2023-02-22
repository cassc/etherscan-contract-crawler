// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NFTCollection.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface INFTCollection {
    function MintNFT(string memory _tokenURI, address _to) external returns(uint256);
}

interface IRegistration {
    function isRegistered(address _user) external view returns(bool);
    function getReferrerAddresses(address _userAddress) external view returns(address[] memory referrerAddresses);
}

contract CentherMarketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct SaleInfo {
        address seller;
        uint256 price;
    }

    struct BidItemInfo {
        uint256 bidPrice;
        address bidAddress;
    }

    struct BidInfo {
        BidItemInfo[] bids;
        uint256 highestBidPrice;
    }

    struct CollectionInfo {
        address creatorAddress;
    }

    uint8 constant referralDeep = 6;
    struct DistributionFee {
        uint32 marketplaceFee;       //1.5%
        uint32 creatorFee;           //1.5%
        uint32[referralDeep] referralFee;        //0.7, 1.4, 2.1, 1.4, 0.7, 0.7%
        uint32 sellerPercentage;     //90%
    }

    enum AuctionState {
        NONE,
        OPEN,
        CANCELED,
        ENDED
    }

    struct AuctionInfo {
        AuctionState state;
        uint256 endAt;
        uint256 startPrice;
        uint256 highestBidPrice;
        address highestBidAddress;
        address seller;
    }

    mapping (address => mapping (uint256 => SaleInfo)) public _nftInfoForSale;
    mapping (address => mapping (uint256 => BidInfo)) public _bidInfo;
    mapping (address => mapping (uint256 => AuctionInfo)) public _nftInfoForAuction;
    mapping (address => CollectionInfo) public _addedCollections;
    DistributionFee public distributionFee;
    uint256 public createItemFeeForTeam;
    uint256 public createItemFeeForCreator;
    uint256 public createCollectionFee;
    uint32 private denominator;

    IWETH public _WETH;
    IRegistration public register;
    
    address[] public _allCollections;

    event NewItemListed(address indexed _collection, uint256 indexed _tokenID, uint256 _price, address _seller);
    event EditItemPrice(address indexed _collection, uint256 indexed _tokenID, uint256 _newPrice, address _seller);
    event CancelItemPrice(address indexed _collection, uint256 indexed _tokenID, address _seller);
    event BuyItem(address indexed _collection, uint256 indexed _tokenID, uint256 _price, address _seller, address _buyer);
    event CreateItem(address indexed _collection, uint256 indexed _tokenID, string _tokenURI, bool _isAuction, uint256 _price, uint256 _endAt, address _creator);
    event BidOnNonAuctionItem(address indexed _collection, uint256 indexed _tokenID, uint256 _newPrice, address _newBidder);
    event AcceptBid(address indexed _collection, uint256 indexed _tokenID, uint256 _price, address _seller, address _buyer);
    event CreateCollection(address indexed _collection, string _collectionName, string _collectionSymbol, string _category, uint256 _maxSupply, string _uri, address _creator);
    event CreateAuction(address indexed _collection, uint256 indexed _tokenID, uint256 _startPrice, uint256 _endAt, address _creator);
    event BidOnAuction(address indexed _collection, uint256 indexed _tokenID, uint256 _newPrice, address _newBidder);
    event EndAuction(address indexed _collection, uint256 indexed _tokenID, uint256 _lastPrice, address _seller, address _lastBidder);
    event CancelAuction(address indexed _collection, uint256 indexed _tokenID, address _seller);
    event ChangeCreateFee(uint256 _createItemFeeForTeam, uint256 _createItemFeeForCreator, uint256 _createCollectionFee);
    event ChangeDistributionFee(uint32 _marketplaceFee, uint32 _creatorFee, uint32 _level1Fee, uint32 _level2Fee, 
        uint32 _level3Fee, uint32 _level4Fee, uint32 _level5Fee, uint32 _level6Fee, uint32 _sellerPercentage);
    modifier onlyRegisterUser {
      require(register.isRegistered(msg.sender), "No registered.");
      _;
    }

    function initialize(address _register, address _weth) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        denominator = 1000;

        register = IRegistration(_register);
        _WETH = IWETH(_weth);
        
        changeDistributionFee(15, 15, 7, 14, 21, 14, 7, 7);
        changeCreateFee(.0072 ether, 0 ether, .0026 ether);
    }

    function changeCreateFee(uint256 _createItemFeeForTeam, uint256 _createItemFeeForCreator, uint256 _createCollectionFee) public onlyOwner() {
        createItemFeeForTeam = _createItemFeeForTeam;
        createItemFeeForCreator = _createItemFeeForCreator;
        createCollectionFee = _createCollectionFee;
        emit ChangeCreateFee(createItemFeeForTeam, createItemFeeForCreator, createCollectionFee);
    }

    function changeDistributionFee(
        uint32 _marketplaceFee, 
        uint32 _creatorFee, 
        uint32 _level1Fee, 
        uint32 _level2Fee, 
        uint32 _level3Fee, 
        uint32 _level4Fee, 
        uint32 _level5Fee, 
        uint32 _level6Fee
        ) public onlyOwner() 
    {
        distributionFee.marketplaceFee = _marketplaceFee;
        distributionFee.creatorFee = _creatorFee;
        distributionFee.referralFee[0] = _level1Fee;
        distributionFee.referralFee[1] = _level2Fee;
        distributionFee.referralFee[2] = _level3Fee;
        distributionFee.referralFee[3] = _level4Fee;
        distributionFee.referralFee[4] = _level5Fee;
        distributionFee.referralFee[5] = _level6Fee;
        distributionFee.sellerPercentage = 
            denominator - distributionFee.marketplaceFee - distributionFee.creatorFee - 
            distributionFee.referralFee[0] - distributionFee.referralFee[1] - distributionFee.referralFee[2] - 
            distributionFee.referralFee[3] - distributionFee.referralFee[4] - distributionFee.referralFee[5];

        emit ChangeDistributionFee(_marketplaceFee, _creatorFee, _level1Fee, _level2Fee, _level3Fee,
            _level4Fee, _level5Fee, _level6Fee, distributionFee.sellerPercentage);
    }

    function createCollection(string memory name, string memory symbol, string memory category, string memory uri, uint256 maxSupply) public payable onlyRegisterUser returns(address) {
        require(msg.value == createCollectionFee, "Insufficient_Funds");
        require(maxSupply > 0, "MAX_SUPPLY must be greater than 0");
        NFTCollection collection = new NFTCollection(name, symbol, maxSupply);
        _addedCollections[address(collection)] = CollectionInfo({creatorAddress: msg.sender});
        _allCollections.push(address(collection));
        emit CreateCollection(address(collection), name, symbol, category, maxSupply, uri, msg.sender);
        return address(collection);
    }

    function createItems(address collection, string memory tokenURI, uint32 supply, bool isAuction, uint256 price, uint256 period) public payable onlyRegisterUser {
        require(msg.value == (createItemFeeForTeam + createItemFeeForCreator) * supply, "Insufficient Funds");
        require(price > 0, "Incorrect Price");
        require(supply > 0, "Incorrect Supply");
        if(isAuction)
            require(period > 0, "Incorrect Auction Period");
        if(createItemFeeForCreator > 0)
            payable(_addedCollections[collection].creatorAddress).transfer(createItemFeeForCreator * supply);
        
        for(uint32 i = 0; i < supply; i++) {
            uint256 tokenID = INFTCollection(collection).MintNFT(tokenURI, address(this));
            if(isAuction) {
                _nftInfoForAuction[collection][tokenID] = AuctionInfo({
                    state: AuctionState.OPEN, 
                    endAt: block.timestamp + period,
                    startPrice: price,
                    highestBidPrice: price,
                    highestBidAddress: address(0x0),
                    seller: msg.sender
                });
            } else {
                _nftInfoForSale[collection][tokenID] = SaleInfo({seller: msg.sender, price: price});
            }            
            emit CreateItem(address(collection), tokenID, tokenURI, isAuction, price, block.timestamp + period, msg.sender);
        }
    }

    function bidOnNonAuctionItem(address collection, uint256 tokenID, uint256 newPrice) public onlyRegisterUser {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        BidInfo storage bidInfo = _bidInfo[collection][tokenID];
        require(bidInfo.highestBidPrice < newPrice, "Incorrect Price");

        bidInfo.highestBidPrice = newPrice;
        bidInfo.bids.push(BidItemInfo({bidPrice: newPrice, bidAddress: msg.sender}));
        emit BidOnNonAuctionItem(collection, tokenID, newPrice, msg.sender);
    }

    function acceptBid(address collection, uint256 tokenID, uint256 index) public onlyRegisterUser nonReentrant {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        BidInfo storage bidInfo = _bidInfo[collection][tokenID];
        bool isListed = IERC721(collection).ownerOf(tokenID) == address(this) && _nftInfoForSale[collection][tokenID].seller == msg.sender;
        require(IERC721(collection).ownerOf(tokenID) == msg.sender || isListed, "Not your NFT");
        
        BidItemInfo memory bid = bidInfo.bids[index];
        _WETH.transferFrom(bid.bidAddress, address(this), bid.bidPrice);
        if(isListed) {
            IERC721(collection).transferFrom(address(this), bid.bidAddress, tokenID);
        } else {
            IERC721(collection).transferFrom(msg.sender, bid.bidAddress, tokenID);
        }
        _nftInfoForSale[collection][tokenID] = SaleInfo({seller: address(0), price: 0});        

        //Transfer money by distribution
        _distributeFundsWETH(
                msg.sender, bid.bidAddress, 
                _addedCollections[collection].creatorAddress, bid.bidPrice);

        emit AcceptBid(collection, tokenID, bid.bidPrice, msg.sender, bid.bidAddress);

        delete bidInfo.bids;
        bidInfo.highestBidPrice = 0;
    }

    function listItemForSale(address collection, uint256 tokenID, uint256 price) public onlyRegisterUser {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        require(IERC721(collection).ownerOf(tokenID) == msg.sender, "Not Your NFT");
        require(IERC721(collection).isApprovedForAll(msg.sender, address(this)), "Not Approved");
        require(price > 0, "Incorrect Price");
        _nftInfoForSale[collection][tokenID] = SaleInfo({seller: msg.sender, price: price});
        IERC721(collection).transferFrom(msg.sender, address(this), tokenID);
        emit NewItemListed(collection, tokenID, price, msg.sender); 
    }

    function editItemForSale(address collection, uint256 tokenID, uint256 newPrice) public onlyRegisterUser {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        require(_nftInfoForSale[collection][tokenID].seller == msg.sender, "Not Your NFT");
        require(IERC721(collection).ownerOf(tokenID) == address(this), "Not listed Item");
        require(newPrice > 0, "Incorrect Price");
        _nftInfoForSale[collection][tokenID] = SaleInfo({seller: msg.sender, price: newPrice});
        emit EditItemPrice(collection, tokenID, newPrice, msg.sender); 
    }

    function cancelItemForSale(address collection, uint256 tokenID) public onlyRegisterUser {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        require(_nftInfoForSale[collection][tokenID].seller == msg.sender, "Not Your NFT");
        _nftInfoForSale[collection][tokenID] = SaleInfo({seller: address(0), price: 0});
        IERC721(collection).transferFrom(address(this), msg.sender, tokenID);
        emit CancelItemPrice(collection, tokenID, msg.sender); 
    }

    function buyForListedItem(address collection, uint256 tokenID) public payable onlyRegisterUser nonReentrant {
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "This is Auction Item");
        SaleInfo memory saleInfo = _nftInfoForSale[collection][tokenID];
        // Verify that the item is for sale
        require(saleInfo.seller != address(0x0) || saleInfo.price != 0, "This item is not for sale");
        // Ensure buyer can't be seller
        require(saleInfo.seller != msg.sender, "Sellers cannot buy from themselves");
        // Ensure price
        require(saleInfo.price == msg.value, "Insufficient price");

        //Transfer NFT to buyer
        IERC721(collection).transferFrom(address(this), msg.sender, tokenID);
        _nftInfoForSale[collection][tokenID] = SaleInfo({seller: address(0), price: 0});

        //Transfer money by distribution
        _distributeFunds(saleInfo.seller, msg.sender, _addedCollections[collection].creatorAddress, msg.value);

        emit BuyItem(collection, tokenID, saleInfo.price, saleInfo.seller, msg.sender);
    }

    function createAuction(address collection, uint256 tokenID, uint256 startPrice, uint256 auctionPeriod) public onlyRegisterUser{
        require(IERC721(collection).ownerOf(tokenID) == msg.sender, "Not Your NFT");
        require(_nftInfoForAuction[collection][tokenID].state != AuctionState.OPEN, "Already Opened");
        require(startPrice > 0, "Incorrect Price");
        require(auctionPeriod > 0, "Incorrect Auction Period");
        
        _nftInfoForAuction[collection][tokenID] = AuctionInfo({
            state: AuctionState.OPEN, 
            endAt: block.timestamp + auctionPeriod,
            startPrice: startPrice,
            highestBidPrice: startPrice,
            highestBidAddress: address(0x0),
            seller: msg.sender
        });
        IERC721(collection).transferFrom(msg.sender, address(this), tokenID);
        emit CreateAuction(collection, tokenID, _nftInfoForAuction[collection][tokenID].startPrice, _nftInfoForAuction[collection][tokenID].endAt, _nftInfoForAuction[collection][tokenID].seller);
    }

    function bidOnAuction(address collection, uint256 tokenID) public payable onlyRegisterUser {
        AuctionInfo storage auctionInfo = _nftInfoForAuction[collection][tokenID];
        require(auctionInfo.state == AuctionState.OPEN, "This is non exist Auction");
        require(auctionInfo.endAt > block.timestamp, "Time over for bid");
        require(auctionInfo.highestBidPrice < msg.value, "Incorrect Price");

        if (auctionInfo.highestBidAddress != address(0x0)) {
            payable(auctionInfo.highestBidAddress).transfer(auctionInfo.highestBidPrice);
        }
        auctionInfo.highestBidPrice = msg.value;
        auctionInfo.highestBidAddress = msg.sender;
        emit BidOnAuction(collection, tokenID, auctionInfo.highestBidPrice, auctionInfo.highestBidAddress);
    }

    function endAuction(address collection, uint256 tokenID) public onlyRegisterUser nonReentrant {
        AuctionInfo storage auctionInfo = _nftInfoForAuction[collection][tokenID];
        require(auctionInfo.state == AuctionState.OPEN, "This is non exist Auction");
        require(auctionInfo.endAt < block.timestamp, "It's not time yet");
        require(auctionInfo.highestBidAddress == msg.sender || auctionInfo.seller == msg.sender, "Not allowed for you");

        IERC721(collection).transferFrom(address(this), msg.sender, tokenID);

        //Transfer money by distribution
        _distributeFunds(
                auctionInfo.seller, auctionInfo.highestBidAddress, 
                _addedCollections[collection].creatorAddress, auctionInfo.highestBidPrice);

        auctionInfo.state = AuctionState.ENDED;
        emit EndAuction(collection, tokenID, auctionInfo.highestBidPrice, auctionInfo.seller, auctionInfo.highestBidAddress);
    }

    function cancelAuction(address collection, uint256 tokenID) public onlyRegisterUser {
        AuctionInfo storage auctionInfo = _nftInfoForAuction[collection][tokenID];
        require(auctionInfo.state == AuctionState.OPEN, "This is non exist Auction");
        require(auctionInfo.seller == msg.sender, "Not allowed for you");
        auctionInfo.state = AuctionState.CANCELED;
        
        if (auctionInfo.highestBidAddress != address(0x0)) {
            payable(auctionInfo.highestBidAddress).transfer(auctionInfo.highestBidPrice);
        }
        emit CancelAuction(collection, tokenID, auctionInfo.seller);
    }

    function _distributeFunds(address _seller, address _buyer, address _creator, uint256 _price) private {

        payable(_creator).transfer(_price * distributionFee.creatorFee / denominator);

        address[] memory referrerAddresses = register.getReferrerAddresses(_buyer);
        for(uint8 i = 0; i < referralDeep; i++) {
            if(referrerAddresses[i] == address(0)) {
                break;
            }
            payable(referrerAddresses[i]).transfer(_price * distributionFee.referralFee[i] / denominator);
        }
        
        payable(_seller).transfer(_price * distributionFee.sellerPercentage / denominator);
    }

    function _distributeFundsWETH(address _seller, address _buyer, address _creator, uint256 _price) private {
        _WETH.transfer(_creator, _price * distributionFee.creatorFee / denominator);

        address[] memory referrerAddresses = register.getReferrerAddresses(_buyer);
        for(uint8 i = 0; i < referralDeep; i++) {
            if(referrerAddresses[i] == address(0)) {
                break;
            }
            _WETH.transfer(referrerAddresses[i], _price * distributionFee.referralFee[i] / denominator);
        }
        
        _WETH.transfer(_seller, _price * distributionFee.sellerPercentage / denominator);
    }

    function getSaleInfo(address _collection, uint256 _id) public view returns(SaleInfo memory){
        return _nftInfoForSale[_collection][_id];
    }

    function getAuctionInfo(address _collection, uint256 _id) public view returns(AuctionInfo memory){
        return _nftInfoForAuction[_collection][_id];
    }

    function getCollectionInfo(address _collection) public view returns(CollectionInfo memory){
        return _addedCollections[_collection];
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0, "No funds");
        payable(owner()).transfer(address(this).balance);
    }
}