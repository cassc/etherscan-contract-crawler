// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Dependencies/Ownable.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/IERC721.sol";
import "./Dependencies/ReentrancyGuard.sol";

contract Sales721ForEth is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // set the saleIDCounter initial value to 1
    uint256 private saleIDCounter = 1;
    bool private onlyInitOnce;

    struct BaseSale {
        // the sale setter
        address seller;
        // addresses of token to sell
        address tokenAddresses;
        // tokenIDs of token to sell
        uint256[] tokenIDs;
        // address of token to pay
        address payTokenAddress;
        // price of token to pay
        uint256 price;
        // address of receiver
        address receiver;
        uint256 startTime;
        uint256 endTime;
        // whether the sale is available
        bool isAvailable;
    }

    struct FlashSale {
        BaseSale base;
        // max number of token could be bought from an address
        uint256 purchaseLimitation;
    }

    struct Auction {
        BaseSale base;
        // the minimum increment in a bid
        uint256 minBidIncrement;
        // the highest price so far
        uint256 highestBidPrice;
        // the highest bidder so far
        address highestBidder;
    }

    struct Activity {
        uint256 limitation;
        uint256 activityId;
        uint256[] salesIDs;
    }

    // whitelist to set sale
    mapping(address => bool) public whitelist;
    // sale ID -> flash sale
    mapping(uint256 => FlashSale) flashSales;
    // sale ID -> mapping(address => how many tokens have bought)
    mapping(uint256 => mapping(address => uint256)) flashSaleIDToPurchaseRecord;
    // sale ID -> auction
    mapping(uint256 => Auction) auctions;
    // filter to check repetition
    mapping(address => mapping(uint256 => bool)) repetitionFilter;

    address public testServerAddress;

    address public serverAddress;
    // sale ID -> server hash
    mapping(bytes32 => uint256) serverHashMap;

    // whitelist to set sale
    mapping(uint256 => bool) public flashSaleOnProd;
    //activityId => activity
    mapping(uint256 => Activity) public activityMap;

    //salesId => activityId
    mapping(uint256 => uint256) public activityIndex;

    bool public enableActivity;

    event SetWhitelist(address _member, bool _isAdded);
    event SetFlashSale(
        uint256 _saleID,
        address _flashSaleSetter,
        address _tokenAddresses,
        uint256[] _tokenIDs,
        address _payTokenAddress,
        uint256 _price,
        address _receiver,
        uint256 _purchaseLimitation,
        uint256 _startTime,
        uint256 _endTime
    );
    event UpdateFlashSale(
        uint256 _saleID,
        address _operator,
        address _newTokenAddresses,
        uint256[] _newTokenIDs,
        address _newPayTokenAddress,
        uint256 _newPrice,
        address _newReceiver,
        uint256 _newPurchaseLimitation,
        uint256 _newStartTime,
        uint256 _newEndTime
    );
    event CancelFlashSale(uint256 _saleID, address _operator);
    event FlashSaleExpired(uint256 _saleID, address _operator);
    event Purchase(
        uint256 _saleID,
        address _buyer,
        address _tokenAddresses,
        uint256[] _tokenIDs,
        address _payTokenAddress,
        uint256 _totalPayment
    );
    event SetAuction(
        uint256 _saleID,
        address _auctionSetter,
        address _tokenAddresses,
        uint256[] _tokenIDs,
        address _payTokenAddress,
        uint256 _initialPrice,
        address _receiver,
        uint256 _minBidIncrement,
        uint256 _startTime,
        uint256 _endTime
    );
    event UpdateAuction(
        uint256 _saleID,
        address _operator,
        address _newTokenAddresses,
        uint256[] _newTokenIDs,
        address _newPayTokenAddress,
        uint256 _newInitialPrice,
        address _newReceiver,
        uint256 _newMinBidIncrement,
        uint256 _newStartTime,
        uint256 _newEndTime
    );
    event RefundToPreviousBidder(
        uint256 _saleID,
        address _previousBidder,
        address _payTokenAddress,
        uint256 _refundAmount
    );
    event CancelAuction(uint256 _saleID, address _operator);
    event NewBidderTransfer(uint256 _saleID, address _newBidder, address _payTokenAddress, uint256 _bidPrice);
    event SettleAuction(
        uint256 _saleID,
        address _operator,
        address _receiver,
        address _highestBidder,
        address _tokenAddresses,
        uint256[] _tokenIDs,
        address _payTokenAddress,
        uint256 _highestBidPrice
    );
    event MainCoin(uint256 totalPayment);
    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "the caller isn't in the whitelist");
        _;
    }

    function init(address _newOwner) public {
        require(!onlyInitOnce, "already initialized");

        _transferOwnership(_newOwner);
        onlyInitOnce = true;
    }

    //return the amount of all sales
    function getActivityTotalAmount(uint256 activityId, address puchaser) public view returns (uint256) {
        Activity memory activity = activityMap[activityId];
        uint256 total;
        for (uint256 i = 0; i < activity.salesIDs.length; i++) {
            uint256 saleId = activity.salesIDs[i];
            total = total + flashSaleIDToPurchaseRecord[saleId][puchaser];
        }
        return total;
    }

    function setActivityStatus(bool enable) external onlyOwner {
        enableActivity = enable;
    }

    function setActivity(Activity memory activity) external onlyOwner {
        activityMap[activity.activityId] = activity;
        for (uint256 i = 0; i < activity.salesIDs.length; i++) {
            uint256 saleId = activity.salesIDs[i];
            activityIndex[saleId] = activity.activityId;
        }
    }

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }

    // set auction by the member in whitelist
    function setAuction(
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        address _payTokenAddress,
        uint256 _initialPrice,
        address _receiver,
        uint256 _minBidIncrement,
        uint256 _startTime,
        uint256 _duration
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkAuctionParams(
            msg.sender,
            _tokenAddresses,
            _tokenIDs,
            _initialPrice,
            _minBidIncrement,
            _startTime,
            _duration
        );

        // 2. build auction
        Auction memory auction = Auction({
            base: BaseSale({
                seller: msg.sender,
                tokenAddresses: _tokenAddresses,
                tokenIDs: _tokenIDs,
                payTokenAddress: _payTokenAddress,
                price: _initialPrice,
                receiver: _receiver,
                startTime: _startTime,
                endTime: _startTime.add(_duration),
                isAvailable: true
            }),
            minBidIncrement: _minBidIncrement,
            highestBidPrice: 0,
            highestBidder: address(0)
        });

        // 3. store auction
        uint256 currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        auctions[currentSaleID] = auction;
        emit SetAuction(
            currentSaleID,
            auction.base.seller,
            auction.base.tokenAddresses,
            auction.base.tokenIDs,
            auction.base.payTokenAddress,
            auction.base.price,
            auction.base.receiver,
            auction.minBidIncrement,
            auction.base.startTime,
            auction.base.endTime
        );
    }

    // update auction by the member in whitelist
    function updateAuction(
        uint256 _saleID,
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        address _payTokenAddress,
        uint256 _initialPrice,
        address _receiver,
        uint256 _minBidIncrement,
        uint256 _startTime,
        uint256 _duration
    ) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // 1. make sure that the auction doesn't start
        require(auction.base.startTime > now, "it's not allowed to update the auction after the start of it");
        require(auction.base.isAvailable, "the auction has been cancelled");
        require(auction.base.seller == msg.sender, "the auction can only be updated by its setter");

        // 2. check the validity of params to update
        _checkAuctionParams(
            msg.sender,
            _tokenAddresses,
            _tokenIDs,
            _initialPrice,
            _minBidIncrement,
            _startTime,
            _duration
        );

        // 3. update the auction
        auction.base.tokenAddresses = _tokenAddresses;
        auction.base.tokenIDs = _tokenIDs;
        auction.base.payTokenAddress = _payTokenAddress;
        auction.base.price = _initialPrice;
        auction.base.receiver = _receiver;
        auction.base.startTime = _startTime;
        auction.base.endTime = _startTime.add(_duration);
        auction.minBidIncrement = _minBidIncrement;
        auctions[_saleID] = auction;
        emit UpdateAuction(
            _saleID,
            auction.base.seller,
            auction.base.tokenAddresses,
            auction.base.tokenIDs,
            auction.base.payTokenAddress,
            auction.base.price,
            auction.base.receiver,
            auction.minBidIncrement,
            auction.base.startTime,
            auction.base.endTime
        );
    }

    // cancel the auction
    function cancelAuction(uint256 _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        require(auction.base.isAvailable, "the auction isn't available");
        require(auction.base.seller == msg.sender, "the auction can only be cancelled by its setter");

        if (auction.highestBidPrice != 0) {
            // some bid has paid for this auction
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(
                _saleID,
                auction.highestBidder,
                auction.base.payTokenAddress,
                auction.highestBidPrice
            );
        }

        auctions[_saleID].base.isAvailable = false;
        emit CancelAuction(_saleID, msg.sender);
    }

    // bid for the target auction
    function bid(uint256 _saleID, uint256 _bidPrice) external nonReentrant {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable, "the auction isn't available");
        require(auction.base.seller != msg.sender, "the setter can't bid for its own auction");
        uint256 currentTime = now;
        require(currentTime >= auction.base.startTime, "the auction doesn't start");
        require(currentTime < auction.base.endTime, "the auction has expired");

        IERC20 payToken = IERC20(auction.base.payTokenAddress);
        // check bid price in auction
        if (auction.highestBidPrice != 0) {
            // not first bid
            require(
                _bidPrice.sub(auction.highestBidPrice) >= auction.minBidIncrement,
                "the bid price must be larger than the sum of current highest one and minimum bid increment"
            );
            // refund to the previous highest bidder from this contract
            payToken.safeTransfer(auction.highestBidder, auction.highestBidPrice);
            emit RefundToPreviousBidder(
                _saleID,
                auction.highestBidder,
                auction.base.payTokenAddress,
                auction.highestBidPrice
            );
        } else {
            // first bid
            require(_bidPrice == auction.base.price, "first bid must follow the initial price set in the auction");
        }

        // update storage auctions
        auctions[_saleID].highestBidPrice = _bidPrice;
        auctions[_saleID].highestBidder = msg.sender;

        // transfer the bid price into this contract
        payToken.safeApprove(address(this), 0);
        payToken.safeApprove(address(this), _bidPrice);
        payToken.safeTransferFrom(msg.sender, address(this), _bidPrice);
        emit NewBidderTransfer(_saleID, msg.sender, auction.base.payTokenAddress, _bidPrice);
    }

    // settle the auction by the member in whitelist
    function settleAuction(uint256 _saleID) external nonReentrant onlyWhitelist {
        Auction memory auction = _getAuctionByID(_saleID);
        // check the validity of the target auction
        require(auction.base.isAvailable, "only the available auction can be settled");
        require(auction.base.endTime <= now, "the auction can only be settled after its end time");

        if (auction.highestBidPrice != 0) {
            // the auction has been bidden
            // transfer pay token to the receiver from this contract
            IERC20(auction.base.payTokenAddress).safeTransfer(auction.base.receiver, auction.highestBidPrice);
            // transfer erc721s to the bidder who keeps the highest price
            for (uint256 i = 0; i < auction.base.tokenIDs.length; i++) {
                IERC721(auction.base.tokenAddresses).safeTransferFrom(
                    auction.base.seller,
                    auction.highestBidder,
                    auction.base.tokenIDs[i]
                );
            }
        }

        // close the auction
        auctions[_saleID].base.isAvailable = false;
        emit SettleAuction(
            _saleID,
            msg.sender,
            auction.base.receiver,
            auction.highestBidder,
            auction.base.tokenAddresses,
            auction.base.tokenIDs,
            auction.base.payTokenAddress,
            auction.highestBidPrice
        );
    }

    event AddTokens(uint256[] _tokenIds, uint256 _saleID);

    function addTokenIdToSale(
        uint256 _saleID,
        address _tokenAddresses,
        uint256[] memory _tokenIDs
    ) external onlyWhitelist {
        uint256 standardLen = _tokenIDs.length;
        require(standardLen > 0, "length of tokenAddresses must be > 0");

        require(flashSales[_saleID].base.startTime > now, "it's not allowed to update the  sale after the start of it");

        require(flashSales[_saleID].base.seller == msg.sender, "the  sale can only be updated by its setter");

        IERC721 tokenAddressCached = IERC721(_tokenAddresses);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 tokenId = _tokenIDs[i];

            require(
                tokenAddressCached.ownerOf(tokenId) == flashSales[_saleID].base.seller,
                "unmatched ownership of target ERC721 token"
            );

            flashSales[_saleID].base.tokenIDs.push(tokenId);
        }

        emit AddTokens(_tokenIDs, _saleID);
    }

    // set flash sale by the member in whitelist
    // NOTE: set 0 duration if you don't want an endTime
    function setFlashSale(
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        address _payTokenAddress,
        uint256 _price,
        address _receiver,
        uint256 _purchaseLimitation,
        uint256 _startTime,
        uint256 _duration,
        bool prod
    ) external nonReentrant onlyWhitelist {
        // 1. check the validity of params
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 2.  build flash sale
        uint256 endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        FlashSale memory flashSale = FlashSale({
            base: BaseSale({
                seller: msg.sender,
                tokenAddresses: _tokenAddresses,
                tokenIDs: _tokenIDs,
                payTokenAddress: _payTokenAddress,
                price: _price,
                receiver: _receiver,
                startTime: _startTime,
                endTime: endTime,
                isAvailable: true
            }),
            purchaseLimitation: _purchaseLimitation
        });

        // 3. store flash sale
        uint256 currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        flashSales[currentSaleID] = flashSale;

        //if true then prod env else test env
        flashSaleOnProd[currentSaleID] = prod;

        emit SetFlashSale(
            currentSaleID,
            flashSale.base.seller,
            flashSale.base.tokenAddresses,
            flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress,
            flashSale.base.price,
            flashSale.base.receiver,
            flashSale.purchaseLimitation,
            flashSale.base.startTime,
            flashSale.base.endTime
        );
    }

    // update the flash sale before starting
    // NOTE: set 0 duration if you don't want an endTime
    function updateFlashSale(
        uint256 _saleID,
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        address _payTokenAddress,
        uint256 _price,
        address _receiver,
        uint256 _purchaseLimitation,
        uint256 _startTime,
        uint256 _duration
    ) external nonReentrant onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // 1. make sure that the flash sale doesn't start
        require(flashSale.base.startTime > now, "it's not allowed to update the flash sale after the start of it");
        require(flashSale.base.isAvailable, "the flash sale has been cancelled");
        require(flashSale.base.seller == msg.sender, "the flash sale can only be updated by its setter");

        // 2. check the validity of params to update
        _checkFlashSaleParams(msg.sender, _tokenAddresses, _tokenIDs, _price, _startTime, _purchaseLimitation);

        // 3. update flash sale
        uint256 endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        flashSale.base.tokenAddresses = _tokenAddresses;
        flashSale.base.tokenIDs = _tokenIDs;
        flashSale.base.payTokenAddress = _payTokenAddress;
        flashSale.base.price = _price;
        flashSale.base.receiver = _receiver;
        flashSale.base.startTime = _startTime;
        flashSale.base.endTime = endTime;
        flashSale.purchaseLimitation = _purchaseLimitation;
        flashSales[_saleID] = flashSale;
        emit UpdateFlashSale(
            _saleID,
            flashSale.base.seller,
            flashSale.base.tokenAddresses,
            flashSale.base.tokenIDs,
            flashSale.base.payTokenAddress,
            flashSale.base.price,
            flashSale.base.receiver,
            flashSale.purchaseLimitation,
            flashSale.base.startTime,
            flashSale.base.endTime
        );
    }

    // cancel the flash sale
    function cancelFlashSale(uint256 _saleID) external onlyWhitelist {
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        require(flashSale.base.isAvailable, "the flash sale isn't available");
        require(flashSale.base.seller == msg.sender, "the flash sale can only be cancelled by its setter");

        flashSales[_saleID].base.isAvailable = false;
        emit CancelFlashSale(_saleID, msg.sender);
    }

    function setServerAddress(address targetAddress) public onlyOwner {
        serverAddress = targetAddress;
    }

    function setTestServerAddress(address targetAddress) public onlyOwner {
        testServerAddress = targetAddress;
    }

    function setFlashSaleEnv(uint256 _saleID, bool isProd) public nonReentrant onlyOwner {
        flashSaleOnProd[_saleID] = isProd;
    }

    // rush to purchase by anyone
    function purchase(
        uint256 _saleID,
        uint256 _amount,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        if (flashSaleOnProd[_saleID] == true) {
            require(ecrecover(hash, v, r, s) == serverAddress, "verify prod server sign failed");
        } else {
            require(ecrecover(hash, v, r, s) == testServerAddress, "verify test server sign failed");
        }
        // we have set saleIDCounter initial value to 1 to prevent when _saleID = 0 from can not being purchased
        require(serverHashMap[hash] != _saleID, "sign hash repeat");

        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        // check the validity
        require(_amount > 0, "amount should be > 0");
        require(flashSale.base.isAvailable, "the flash sale isn't available");
        require(flashSale.base.seller != msg.sender, "the setter can't make a purchase from its own flash sale");
        uint256 currentTime = now;
        require(currentTime >= flashSale.base.startTime, "the flash sale doesn't start");
        // check whether the end time arrives
        if (flashSale.base.endTime != 0 && flashSale.base.endTime <= currentTime) {
            // the flash sale has been set an end time and expired
            flashSales[_saleID].base.isAvailable = false;
            emit FlashSaleExpired(_saleID, msg.sender);
            return;
        }
        // check the purchase record of the buyer
        uint256 newPurchaseRecord = flashSaleIDToPurchaseRecord[_saleID][msg.sender].add(_amount);

        if (enableActivity) {
            Activity memory activity = activityMap[activityIndex[_saleID]];
            uint256 activityAmount = getActivityTotalAmount(activity.activityId, msg.sender);
            require(
                activityAmount.add(newPurchaseRecord) <= activity.limitation,
                "total amount to purchase for activity exceeds the limitation of an address"
            );
        }

        require(
            newPurchaseRecord <= flashSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address"
        );
        // check whether the amount of token rest in flash sale is sufficient for this trade
        require(_amount <= flashSale.base.tokenIDs.length, "insufficient amount of token for this trade");

        // pay the receiver
        flashSaleIDToPurchaseRecord[_saleID][msg.sender] = newPurchaseRecord;
        uint256 totalPayment = flashSale.base.price.mul(_amount);
        //IERC20(flashSale.base.payTokenAddress).safeTransferFrom(msg.sender, flashSale.base.receiver, totalPayment);

        if (flashSale.base.payTokenAddress != address(0)) {
            IERC20(flashSale.base.payTokenAddress).safeTransferFrom(msg.sender, flashSale.base.receiver, totalPayment);
        } else {
            require(msg.value >= totalPayment, "amount should be > totalPayment");
            emit MainCoin(totalPayment);
            payable(flashSale.base.receiver).transfer(totalPayment);
        }

        // transfer erc721 tokens to buyer
        uint256[] memory tokenIDsRecord = new uint256[](_amount);
        uint256 targetIndex = flashSale.base.tokenIDs.length - 1;
        for (uint256 i = 0; i < _amount; i++) {
            IERC721(flashSale.base.tokenAddresses).safeTransferFrom(
                flashSale.base.seller,
                msg.sender,
                flashSale.base.tokenIDs[targetIndex]
            );
            tokenIDsRecord[i] = flashSale.base.tokenIDs[targetIndex];
            targetIndex--;
            flashSales[_saleID].base.tokenIDs.pop();
        }

        if (flashSales[_saleID].base.tokenIDs.length == 0) {
            flashSales[_saleID].base.isAvailable = false;
        }

        serverHashMap[hash] = _saleID;
        //event Purchase(uint _saleID, address _buyer, address _tokenAddresses, uint[] _tokenIDs, address _payTokenAddress, uint _totalPayment);
        emit Purchase(
            _saleID,
            msg.sender,
            flashSale.base.tokenAddresses,
            tokenIDsRecord,
            flashSale.base.payTokenAddress,
            totalPayment
        );
    }

    function getFlashSaleTokenRemaining(uint256 _saleID) public view returns (uint256) {
        // check whether the flash sale ID exists
        FlashSale memory flashSale = _getFlashSaleByID(_saleID);
        return flashSale.base.tokenIDs.length;
    }

    function getFlashSalePurchaseRecord(uint256 _saleID, address _buyer) public view returns (uint256) {
        // check whether the flash sale ID exists
        _getFlashSaleByID(_saleID);
        return flashSaleIDToPurchaseRecord[_saleID][_buyer];
    }

    function getAuctionTokenAmount(uint256 _saleID) public view returns (uint256 amount) {
        Auction memory auction = auctions[_saleID];
        amount = auction.base.tokenIDs.length;
    }

    function getFlashSaleTokenAmount(uint256 _saleID) public view returns (uint256 amount) {
        FlashSale memory flashSale = flashSales[_saleID];
        amount = flashSale.base.tokenIDs.length;
    }

    function getAuction(uint256 _saleID) public view returns (Auction memory) {
        return _getAuctionByID(_saleID);
    }

    function getFlashSale(uint256 _saleID) public view returns (FlashSale memory) {
        return _getFlashSaleByID(_saleID);
    }

    function getCurrentSaleID() external view returns (uint256) {
        return saleIDCounter;
    }

    function _getAuctionByID(uint256 _saleID) internal view returns (Auction memory auction) {
        auction = auctions[_saleID];
        require(auction.base.seller != address(0), "the target auction doesn't exist");
    }

    function _getFlashSaleByID(uint256 _saleID) internal view returns (FlashSale memory flashSale) {
        flashSale = flashSales[_saleID];
        require(flashSale.base.seller != address(0), "the target flash sale doesn't exist");
    }

    function _checkAuctionParams(
        address _baseSaleSetter,
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        uint256 _initialPrice,
        uint256 _minBidIncrement,
        uint256 _startTime,
        uint256 _duration
    ) internal {
        _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _initialPrice, _startTime);
        require(_minBidIncrement > 0, "minBidIncrement must be > 0");
        require(_duration > 0, "duration must be > 0");
    }

    function _checkFlashSaleParams(
        address _baseSaleSetter,
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        uint256 _price,
        uint256 _startTime,
        uint256 _purchaseLimitation
    ) internal {
        uint256 standardLen = _checkBaseSaleParams(_baseSaleSetter, _tokenAddresses, _tokenIDs, _price, _startTime);
        require(_purchaseLimitation > 0, "purchaseLimitation must be > 0");
        /*  require(_purchaseLimitation <= standardLen,
            "purchaseLimitation must be <= the length of tokenAddresses");*/
    }

    function _checkBaseSaleParams(
        address _baseSaleSetter,
        address _tokenAddresses,
        uint256[] memory _tokenIDs,
        uint256 _price,
        uint256 _startTime
    ) internal returns (uint256 standardLen) {
        standardLen = _tokenIDs.length;
        // check whether the sale setter has the target tokens && approval
        IERC721 tokenAddressCached = IERC721(_tokenAddresses);
        uint256 tokenIDCached;
        for (uint256 i = 0; i < standardLen; i++) {
            tokenIDCached = _tokenIDs[i];
            // check repetition
            require(!repetitionFilter[address(tokenAddressCached)][tokenIDCached], "repetitive ERC721 tokens");
            repetitionFilter[address(tokenAddressCached)][tokenIDCached] = true;
            require(
                tokenAddressCached.ownerOf(tokenIDCached) == _baseSaleSetter,
                "unmatched ownership of target ERC721 token"
            );
            require(
                tokenAddressCached.getApproved(tokenIDCached) == address(this) ||
                    tokenAddressCached.isApprovedForAll(_baseSaleSetter, address(this)),
                "the contract hasn't been approved for ERC721 transferring"
            );
        }

        require(_price >= 0, "the price or the initial price must be >= 0");
        require(_startTime >= now, "startTime must be >= now");

        // clear filter
        for (uint256 i = 0; i < standardLen; i++) {
            repetitionFilter[_tokenAddresses][_tokenIDs[i]] = false;
        }
    }

    using Address for address payable;
    using Address for address;

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token.isContract()) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            payable(to).sendValue(amount);
        }
        emit EmergencyWithdraw(token, to, amount);
    }

    event EmergencyWithdraw(address token, address to, uint256 amount);
}