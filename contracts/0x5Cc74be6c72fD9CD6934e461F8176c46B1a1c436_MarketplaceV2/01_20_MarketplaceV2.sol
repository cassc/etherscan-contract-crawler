// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AisNft.sol";
import "./Pausable.sol";
import "./IMarketplace.sol";

contract MarketplaceV2 is Initializable, Pausable, AccessControlUpgradeable, IMarketplace {

    bytes32 public constant AUCTION_FINISHER_ROLE = keccak256("AUCTION_FINISHER_ROLE");

    //** vars */
    uint32 public foundationFee; // 2% to foundationAddress (only initial sale)
    uint32 public adminFee; // 8% to adminAddress on initial sale

    uint32 public adminFeeOnResell; // 2.5% to adminAddress on resell
    uint32 public creatorFee;// 7.5% creator (init artist) on resell (from this 7.5% we also pay collaborators fees)

    //** structs */

    struct Sale {
        uint32 quantity;
        uint256 price;
        address seller;
        bool resell;
    }

    struct AuctionState {
        bool active;
        uint256 creationTime;
        uint32 duration;
        uint256 price;
        uint256 reservePrice;
        address seller;
        bool resell;
        uint256 highestBid;
        address highestBidder;
    }

    //** mappings */
    mapping(address => uint256) public _fundRecord;

    mapping(uint256 => mapping(address => Sale)) _sailingBox;
    mapping(uint256 => AuctionState) _auctionState;

    address foundationAddress;

    address adminAddress;

    AisNft aisNft;

    //** events */

    // v2 variables
    uint32 public buyNowPercentage;// 40% minPrice must be at least 40% of buyNow
    uint32 public reservePercentage;// 80%

    uint32 public auctionMinDuration;// 15 min
    uint32 public auctionMaxDuration;// 30 days
    uint32 public afterBidDuration;// 15 min
    uint32 public afterBidDurationNoResPrice;// 6 hour

    mapping(uint256 => uint256) _auctionFinishAllowTime;

    event NftItemSold(uint256 tokenId, uint256 price, uint32 qty, address seller, address buyer, bool wasAuction);

    event SaleCreated(uint256 tokenId, address creator, uint32 qty, uint256 price, bool isResell);

    event SaleDropped(uint256 tokenId, address creator);

    event AuctionCreated(
        uint256 tokenId, address creator, uint256 minPrice, uint256 reservePrice, uint256 buyNowPrice, bool isResell,
        uint256 createTime, uint32 duration
    );

    event BidCreated(uint256 tokenId, address bidder, uint256 newBid);

    event BidWithdrawn(uint256 tokenId, address bidder);

    event AuctionClosed(uint256 tokenId, address seller, address caller);

    event FundAdded(address user, uint256 amount);

    event FundDropped(address user, uint256 amount);

    function initialize(address _nft) public initializer {
        aisNft = AisNft(_nft);

        foundationFee = 200;
        adminFee = 800;

        adminFeeOnResell = 250;
        creatorFee = 750;

        foundationAddress = 0x36cDFAEE214a22584A900129dd3b2704Ec3cAB7a;
        adminAddress = 0x8A58f8Ab955313DE64633F7Dc61F2dB1F12b9952;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(AUCTION_FINISHER_ROLE, _msgSender());

        __Ownable_init();
    }

    function initializeV2() public {
        buyNowPercentage = 4000;
        reservePercentage = 8000;

        auctionMinDuration = 900;
        auctionMaxDuration = 2592000;
        afterBidDuration = 900;
        afterBidDurationNoResPrice = 21600;
    }


    function changeFoundationAddress(address _newAddress) public onlyOwner returns (bool)  {
        foundationAddress = _newAddress;
        return true;
    }


    function changeAdminAddress(address _newAddress) public onlyOwner returns (bool)  {
        adminAddress = _newAddress;
        return true;
    }

    function changeBuyNowPercentage(uint32 _buyNowPercentage) public onlyOwner returns (bool)  {
        buyNowPercentage = _buyNowPercentage;
        return true;
    }

    function changeReservePercentage(uint32 _reservePercentage) public onlyOwner returns (bool)  {
        reservePercentage = _reservePercentage;
        return true;
    }

    function changeAuctionMinDuration(uint32 _auctionMinDuration) public onlyOwner returns (bool)  {
        auctionMinDuration = _auctionMinDuration;
        return true;
    }

    function changeAuctionMaxDuration(uint32 _auctionMaxDuration) public onlyOwner returns (bool)  {
        auctionMaxDuration = _auctionMaxDuration;
        return true;
    }

    function changeAfterBidDuration(uint32 _afterBidDuration) public onlyOwner returns (bool)  {
        afterBidDuration = _afterBidDuration;
        return true;
    }

    function changeAfterBidDurationNoResPrice(uint32 _afterBidDurationNoResPrice) public onlyOwner returns (bool)  {
        afterBidDurationNoResPrice = _afterBidDurationNoResPrice;
        return true;
    }

    // modifiers

    modifier onlyTokenOwner(uint256 _tokenId, uint256 _quantity)  {
        require(aisNft.balanceOf(msg.sender, _tokenId) >= _quantity, "Not owner");
        _;
    }

    modifier onlySeller(uint256 _tokenId)  {
        require(_sailingBox[_tokenId][msg.sender].seller == msg.sender, "Not a seller");
        _;
    }

    modifier onlyActiveAuction(uint256 _tokenId)  {
        require(_auctionState[_tokenId].active, "This Auction is unavailable!");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    // public views

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSailingList(uint256 _tokenId) public view returns (Sale memory) {
        return _sailingBox[_tokenId][msg.sender];
    }

    function getSailingParams(uint256 _tokenId, address _seller) public view returns (uint256, uint32){
        return (_sailingBox[_tokenId][_seller].price, _sailingBox[_tokenId][_seller].quantity);
    }

    function getStateAuction(uint256 _tokenId) public view returns (AuctionState memory){
        return _auctionState[_tokenId];
    }

    function getAuctionEndTime(uint256 _tokenId) public view returns (uint256) {
        return _auctionFinishAllowTime[_tokenId];
    }

    function isActiveAuction(uint256 _tokenId) external override view returns (bool) {
        return _auctionState[_tokenId].active;
    }

    function getUserFund(address user) public view returns (uint256) {
        return _fundRecord[user];
    }

    // externals

    // seller

    function createSailing(
        string memory _uri,
        uint256 _price,
        uint32 _quantity,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    priceGreaterThanZero(_price) notPaused
    external returns (bool, uint256)
    {
        uint256 tokenId = aisNft.createNftItem(msg.sender, _uri, _quantity, _galleryFee, _galleryAddress, _collaborators, _collaboratorsFee);
        _setupSale(tokenId, _quantity, _price, false);

        return (true, tokenId);
    }

    function resell(uint256 _tokenId, uint32 _quantity, uint256 _price)
    priceGreaterThanZero(_price) onlyTokenOwner(_tokenId, _quantity) notPaused
    external returns (bool)
    {
        require(!_auctionState[_tokenId].active, "resale is forbidden on active auction");
        require(!aisNft.getNftItem(_tokenId).isMembership, "Membership token can't be sold");

        _setupSale(_tokenId, _quantity, _price, true);
        return true;
    }

    function dropSailingList(uint256 _tokenId) external onlySeller(_tokenId) notPaused returns (bool) {

        delete _sailingBox[_tokenId][msg.sender];
        emit SaleDropped(_tokenId, msg.sender);

        return true;
    }

    function createAuction(string memory _uri,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint256 _reservePrice,
        uint32 _duration,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    priceGreaterThanZero(_minPrice) notPaused
    external returns (uint256)
    {

        uint256 tokenId = aisNft.createNftItem(msg.sender, _uri, 1, _galleryFee, _galleryAddress, _collaborators, _collaboratorsFee);
        _setupAuction(tokenId, _minPrice, _reservePrice, _buyNowPrice, _duration, false);
        return tokenId;
    }

    function resaleWithAuction(uint256 _tokenId, uint256 _minPrice, uint256 _buyNowPrice, uint256 _reservePrice, uint32 _duration)
    priceGreaterThanZero(_minPrice) onlyTokenOwner(_tokenId, 1) notPaused
    external returns (bool) {

        require(!_auctionState[_tokenId].active, "resale is forbidden on active auction");
        require(aisNft.getNftItem(_tokenId).quantity == 1, "Only NFT with 1 of a kind can create auction");
        require(!aisNft.getNftItem(_tokenId).isMembership, "Membership token can't be sold");

        _setupAuction(_tokenId, _minPrice, _reservePrice, _buyNowPrice, _duration, true);
        return true;
    }


    // buyer

    function multiBuy(uint256[] memory _tokenIds, uint32[] memory _quantities, address[] memory _sellers) notPaused external payable returns (bool)
    {
        uint256 leftValue = msg.value;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            leftValue -= _buy(_tokenIds[i], _quantities[i], _sellers[i], leftValue);
        }
        if (leftValue > 0) {
            _addFunds(msg.sender, leftValue);
        }
        return true;
    }

    function buy(uint256 _tokenId, uint32 _quantity, address _seller) notPaused external payable returns (bool)
    {
        uint256 leftValue = msg.value;

        leftValue -= _buy(_tokenId, _quantity, _seller, leftValue);

        if (leftValue > 0) {
            _addFunds(msg.sender, leftValue);
        }
        return true;
    }


    function bidAuction(uint256 _tokenId, uint256 _newBid) external onlyActiveAuction(_tokenId) notPaused returns (bool){

        AuctionState memory auction = _auctionState[_tokenId];

        require(auction.seller != msg.sender, "Seller can not be buyer");
        require(_newBid >= auction.price, "Price must be bigger then starting price");
        require(_newBid > auction.highestBid, "Price must be bigger then highest bid");
        require(_auctionFinishAllowTime[_tokenId] > block.timestamp, "auction time is over");

        require(aisNft.balanceOf(auction.seller, _tokenId) >= 1, "Seller address does not hold token");

        uint256 buyNowPrice = _sailingBox[_tokenId][auction.seller].price;

        if (buyNowPrice > 0) {
            require(_newBid < buyNowPrice, "Bidding amount must be less then buyNow");
        }

        uint256 addon = _newBid;
        if (auction.highestBidder == msg.sender) {
            addon -= auction.highestBid;
        } else {
            _refundLastBid(_tokenId);
        }

        require(_fundRecord[msg.sender] >= addon, "Not enough funds for bidding");

        _fundRecord[msg.sender] -= addon;

        _auctionState[_tokenId].highestBid = _newBid;
        _auctionState[_tokenId].highestBidder = msg.sender;

        if (_newBid >= _auctionState[_tokenId].reservePrice) {
            _auctionFinishAllowTime[_tokenId] = block.timestamp + afterBidDuration;
        } else {
            _auctionFinishAllowTime[_tokenId] = block.timestamp + afterBidDurationNoResPrice;
        }

        emit BidCreated(_tokenId, msg.sender, _newBid);
        return true;
    }

    function endAuction(uint256 _tokenId) external
    onlyActiveAuction(_tokenId) notPaused returns (bool)
    {
        require(block.timestamp > _auctionFinishAllowTime[_tokenId], "auction time is not over");

        _endAuction(_tokenId);
        return true;
    }

    function endAuctionBySeller(uint256 _tokenId, bool _close) external
    onlyTokenOwner(_tokenId, 1) onlyActiveAuction(_tokenId) notPaused returns (bool)
    {
        if (_close) {

            if (_auctionFinishAllowTime[_tokenId] > block.timestamp) {
                require(_auctionState[_tokenId].highestBid == 0, "close is not permitted");
            } else {
                require(
                    _auctionState[_tokenId].highestBid == 0 ||
                    _auctionState[_tokenId].highestBid < _auctionState[_tokenId].reservePrice,
                    "close is not permitted"
                );
            }
            _closeAuction(_tokenId);

        } else {
            _endAuction(_tokenId);
        }
        return true;
    }


    function addFund(uint256 _amount) notPaused external payable returns (bool)
    {
        require(_amount > 0 && _amount == msg.value, "Please submit the valid amounts!");

        _fundRecord[msg.sender] += _amount;

        emit FundAdded(msg.sender, _amount);
        return true;
    }

    function dropFund(uint256 _amount) external returns (bool)
    {
        require(_amount > 0 && _amount <= _fundRecord[msg.sender], "Please submit the valid amounts!");

        _fundRecord[msg.sender] -= _amount;
        _payout(msg.sender, _amount, false);

        emit FundDropped(msg.sender, _amount);

        return true;
    }

    //  internals

    function _setupSale(uint256 _tokenId, uint32 _quantity, uint256 _price, bool _resell) internal {

        _sailingBox[_tokenId][msg.sender] = Sale(_quantity, _price, msg.sender, _resell);
        emit SaleCreated(_tokenId, msg.sender, _quantity, _price, _resell);
    }

    function _setupAuction(
        uint256 _tokenId, uint256 _minPrice, uint256 _reservePrice, uint256 _buyNowPrice, uint32 _duration, bool _resell)
    internal {

        require(_duration >= auctionMinDuration && _duration <= auctionMaxDuration, "duration is not valid");

        if (_buyNowPrice > 0) {

            require(_calculatePercentage(_buyNowPrice, buyNowPercentage) >= _minPrice, "buyNowPrice must be more");
            // setting this will allow buy with one click
            _sailingBox[_tokenId][msg.sender] = Sale(1, _buyNowPrice, msg.sender, _resell);
        }

        _auctionFinishAllowTime[_tokenId] = block.timestamp + _duration;

        _auctionState[_tokenId] = AuctionState(true, block.timestamp, _duration, _minPrice, _reservePrice, msg.sender, _resell, 0, address(0));

        emit AuctionCreated(_tokenId, msg.sender, _minPrice, _reservePrice, _buyNowPrice, _resell, block.timestamp, _duration);
    }


    function _buy(uint256 _tokenId, uint32 _quantity, address _seller, uint256 _totalAmountLeft) internal returns (uint256) {

        uint32 quantity = _sailingBox[_tokenId][_seller].quantity;
        uint256 price = _sailingBox[_tokenId][_seller].price;
        address seller = _sailingBox[_tokenId][_seller].seller;
        bool isResell = _sailingBox[_tokenId][_seller].resell;

        require(seller != msg.sender, "Seller can not be buyer");
        require(aisNft.balanceOf(seller, _tokenId) >= _quantity, "Seller address does not hold token(s)");

        uint256 total = price * _quantity;

        require(_totalAmountLeft >= total, "Price must be bigger to listing price");
        require(_quantity <= quantity, "Quantity can't be more then listing");

        //uint _tokenId,address creator,address OwnerOFToken,uint price
        _sailingBox[_tokenId][_seller].quantity -= _quantity;

        if (_auctionState[_tokenId].active) {
            require(
                _calculatePercentage(total, reservePercentage) > _auctionState[_tokenId].highestBid,
                "buyNow price is disabled"
            );
            _closeAuction(_tokenId);
        }

        aisNft.marketplaceTransfer(_seller, msg.sender, _tokenId, _quantity);
        _separateFees(_tokenId, seller, total, isResell);

        emit NftItemSold(_tokenId, price, _quantity, _seller, msg.sender, false);

        return total;
    }

    function _endAuction(uint256 _tokenId) internal {

        require(
            _auctionState[_tokenId].highestBid >= _auctionState[_tokenId].price, "bid is not made"
        );

        address winner = _auctionState[_tokenId].highestBidder;
        uint256 bidAmount = _auctionState[_tokenId].highestBid;

        bool isResell = _auctionState[_tokenId].resell;

        address seller = _auctionState[_tokenId].seller;

        _sailingBox[_tokenId][seller].seller = address(0);
        _sailingBox[_tokenId][seller].price = 0;
        _sailingBox[_tokenId][seller].quantity = 0;

        delete _auctionState[_tokenId];
        delete _auctionFinishAllowTime[_tokenId];

        aisNft.marketplaceTransfer(seller, winner, _tokenId, 1);
        _separateFees(_tokenId, seller, bidAmount, isResell);

        emit NftItemSold(_tokenId, bidAmount, 1, seller, winner, true);
    }

    function _closeAuction(uint256 _tokenId) internal {
        _refundLastBid(_tokenId);
        address seller = _auctionState[_tokenId].seller;
        delete _auctionState[_tokenId];
        delete _auctionFinishAllowTime[_tokenId];
        emit AuctionClosed(_tokenId, seller, msg.sender);
    }

    function _refundLastBid(uint256 _tokenId) internal {
        if (_auctionState[_tokenId].highestBid > 0) {
            _addFunds(_auctionState[_tokenId].highestBidder, _auctionState[_tokenId].highestBid);
            emit BidWithdrawn(_tokenId, _auctionState[_tokenId].highestBidder);
        }
    }

    function _separateFees(uint256 _tokenId, address _seller, uint256 _price, bool _resell) internal returns (bool)
    {
        AisNft.NftItem memory nft = aisNft.getNftItem(_tokenId);

        address creator = nft.creator;

        uint256 foundationPart;
        uint256 adminPart;
        uint256 galleryPart;
        uint256 creatorPart;
        uint256 resellerPart;

        if (creator == adminAddress && !_resell) {

            foundationPart = _calculatePercentage(_price, foundationFee);
            creatorPart = _price - foundationPart;

        } else {

            if (!_resell) {

                foundationPart = _calculatePercentage(_price, foundationFee);
                adminPart = _calculatePercentage(_price, adminFee);

                if (nft.isGallery) {
                    galleryPart = _calculatePercentage((_price - foundationPart - adminPart), nft.galleryFee);
                }

                creatorPart = _price - foundationPart - adminPart - galleryPart;

            } else {

                adminPart = _calculatePercentage(_price, adminFeeOnResell);
                creatorPart = _calculatePercentage(_price, creatorFee);
                resellerPart = _price - adminPart - creatorPart;
            }
        }

        if (foundationPart > 0) {
            _fundRecord[foundationAddress] += foundationPart;
        }
        if (adminPart > 0) {
            _fundRecord[adminAddress] += adminPart;
        }
        if (galleryPart > 0) {
            _fundRecord[nft.galleryAddress] += galleryPart;
        }
        if (resellerPart > 0) {
            _fundRecord[_seller] += resellerPart;
        }
        if (creatorPart > 0) {

            uint256 feesPaid = 0;
            for (uint256 i = 0; i < nft.collaborators.length; i++) {
                uint256 fee = _calculatePercentage(creatorPart, nft.collaboratorsFee[i]);
                feesPaid += fee;
                _fundRecord[nft.collaborators[i]] += fee;
            }
            _fundRecord[creator] += (creatorPart - feesPaid);
        }

        return true;
    }

    function _addFunds(address _user, uint256 _amount) internal returns (bool)
    {
        _fundRecord[_user] += _amount;
        emit FundAdded(_user, _amount);
        return true;
    }

    function _payout(address _recipient, uint256 _amount, bool addInFundsOnFail) internal returns (bool) {
        // attempt to send the funds to the recipient
        (bool success,) = payable(_recipient).call{value : _amount, gas : 20000}("");
        // if it failed, update their credit balance so they can pull it later

        if (!success) {
            if (addInFundsOnFail) {
                _addFunds(_recipient, _amount);
            } else {
                require(success, "payout failed");
            }
        }
        return success;
    }

    function _calculatePercentage(uint256 _totalAmount, uint32 _percentage)
    internal
    pure
    returns (uint256)
    {
        return (_totalAmount * (_percentage)) / 10000;
    }

}