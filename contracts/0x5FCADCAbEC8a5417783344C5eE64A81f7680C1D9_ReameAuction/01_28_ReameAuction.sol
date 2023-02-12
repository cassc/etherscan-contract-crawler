// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IReameNFT.sol";
import "./interfaces/IFeeManager.sol";

import "./libraries/Auctions.sol";
import "./libraries/Bids.sol";
import "./NativeWrapper.sol";

contract ReameAuction is AccessControlUpgradeable, ERC721HolderUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Auctions for Auctions.Auction;
    using Auctions for Auctions.Auction[];
    using Bids for Bids.Bid;
    using Bids for Bids.Bid[];
        
    modifier onlyAdmin 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    IFeeManager public feeManager;
    IReameNFT public reameNft;
    
    Counters.Counter private _auctionIdTracker;
    Counters.Counter private _bidIdTracker;

    // auction id => Auction
    mapping(uint256 => Auctions.Auction) public auctionMap;

    // [auction id]
    EnumerableSet.UintSet private auctions;

    // token id => [auction id]
    mapping(uint256 => EnumerableSet.UintSet) private auctionsOfToken;

    // auction id => the last bid
    mapping(uint256 => Bids.Bid) public lastBidOfAuction;

    // auction id => [bid id]
    mapping(uint256 => EnumerableSet.UintSet) private bids;

    // bid id => Bid
    mapping(uint256 => Bids.Bid) public bidMap;

    NativeWrapper public wrapper;

    receive() external payable {}

    function initialize(address _admin, address _feeManager, address _reameNft) 
        public initializer
    {
        __AccessControl_init_unchained();
        __ERC721Holder_init_unchained();
        __JAuction_init_unchained(_admin, _feeManager, _reameNft);
    }

    function __JAuction_init_unchained(address _admin, address _feeManager, address _reameNft)
        internal initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);        
        feeManager = IFeeManager(_feeManager);
        reameNft = IReameNFT(_reameNft);
        _auctionIdTracker.increment(); // start at id = 1
        _bidIdTracker.increment(); // start at id = 1
    }

    function updateTime(
        uint256 _auctionId,
        uint256 _startTime, 
        uint256 _endTime
    ) external onlyAdmin {
        require(_startTime < _endTime && _endTime > currentTime(), "invalid time");
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        require(_auction.active, "not active");
        _auction.startTime = _startTime;
        _auction.endTime = _endTime;
        
        emit UpdateTime(_auctionId, _startTime, _endTime);
    }

    function cancel(
        uint256 _auctionId
    ) external {
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        require(_auction.active, "not active");
        require(_auction.owner == msg.sender, "permission denied");
        Bids.Bid memory _lastBid = lastBidOfAuction[_auctionId];
        require(_lastBid.owner == address(0), "already had bidder");

        _auction.active = false;

        reameNft.safeTransferFrom(address(this), _auction.owner, _auction.tokenId, "");

        emit Cancel(_auctionId);
    }

    function start(
        uint256 _tokenId, 
        address _acceptedToken, 
        uint256 _price, 
        uint256 _startTime, 
        uint256 _endTime,
        uint256 _step)
        external returns (uint256 _auctionId)
    {
        require(reameNft.ownerOf(_tokenId) == msg.sender, "not owner token");
        require(_acceptedToken != address(0), "invalid address");
        require(_price != 0, "invalid price");
        require(_startTime < _endTime, "invalid time");

        _auctionId = _auctionIdTracker.current();

        Auctions.Auction memory auction = Auctions.Auction({
            auctionId: _auctionId,
            owner: msg.sender,
            tokenId: _tokenId,
            acceptedToken: _acceptedToken,
            price: _price,
            soldPrice: 0,
            startTime: _startTime,
            endTime: _endTime,
            step: _step,
            active: true
        });
        auctionMap[_auctionId] = auction;
        auctions.add(_auctionId);
        auctionsOfToken[_tokenId].add(_auctionId);

        reameNft.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        _auctionIdTracker.increment();

        emit Start(_auctionId, msg.sender, _tokenId, _acceptedToken, _price, _startTime, _endTime);
    }

    function bid(uint256 _auctionId, uint256 _price)
        payable external returns (uint256 _bidId)
    {
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        Bids.Bid memory _lastBid = lastBidOfAuction[_auctionId];
        require(_auction.active, "not active");
        require(_auction.endTime > currentTime(), "expired");
        require(_lastBid.owner != msg.sender, "no need to bid");
        require(_lastBid.price.add(_auction.step) <= _price, "invalid price");

        _bidId = _bidIdTracker.current();
        Bids.Bid memory _bid = Bids.Bid({
            bidId: _bidId,
            owner: msg.sender,
            auctionId: _auctionId,
            acceptedToken: _auction.acceptedToken,
            price: _price,
            timestamp: block.timestamp
        });

        bidMap[_bidId] = _bid;
        bids[_auctionId].add(_bidId);

        if (_auction.endTime.sub(currentTime()) <= 15 minutes) {
            _auction.endTime = _auction.endTime.add(15 minutes);
            emit UpdateTime(_auctionId, _auction.startTime, _auction.endTime);
        }

        // return locked token to the last bidder
        if (_lastBid.price > 0) {
            _sendAcceptedToken(_auction.acceptedToken, _lastBid.owner, _lastBid.price);
        }

        if (_auction.acceptedToken == address(wrapper)) {
            require(msg.value >= _price, "not enough native");
        } else {
            IERC20(_auction.acceptedToken).safeTransferFrom(msg.sender, address(this), _price);
        }

        lastBidOfAuction[_auctionId] = _bid;
        _bidIdTracker.increment();

        emit Bid(_bidId, msg.sender, _auctionId, _price);
    }

    function buyNow(uint256 _auctionId)
        payable external
    {
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        require(_auction.active, "not active");
        require(_auction.endTime > currentTime(), "expired");

        Bids.Bid memory _lastBid = lastBidOfAuction[_auctionId];

        _auction.active = false;
        _auction.soldPrice = _auction.price;

        if (_lastBid.bidId != 0) { // has bidder
            _sendAcceptedToken(_auction.acceptedToken, _lastBid.owner, _lastBid.price);
        } 

        if (_auction.acceptedToken == address(wrapper)) {
            require(msg.value >= _auction.price, "not enough native");
        } else {
            IERC20(_auction.acceptedToken).safeTransferFrom(msg.sender, address(this), _auction.price);
        }

        uint256 _platformFee = feeManager.calculateFee(_auction.acceptedToken, _auction.price);
        uint256 _royaltyFee = reameNft.calculateRoyaltyFee(_auction.tokenId, _auction.price);
        uint256 _finalAmount = _auction.price.sub(_platformFee).sub(_royaltyFee);
        address _creator = reameNft.creatorOf(_auction.tokenId);
        address _feeCollector = feeManager.getFeeCollector();

        if (_auction.acceptedToken == address(wrapper)) {
            payable(_feeCollector).transfer(_platformFee);
            payable(_creator).transfer(_royaltyFee);
            payable(_auction.owner).transfer(_finalAmount);
        } else {
            IERC20(_auction.acceptedToken).safeTransfer(_feeCollector, _platformFee);
            IERC20(_auction.acceptedToken).safeTransfer(_creator, _royaltyFee);
            IERC20(_auction.acceptedToken).safeTransfer(_auction.owner, _finalAmount);
        }

        reameNft.safeTransferFrom(address(this), msg.sender, _auction.tokenId, "");

        emit BuyNow(msg.sender, _auctionId, _auction.price);
    }

    function claim(uint256 _auctionId)
        external
    {
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        require(_auction.active, "not active");
        require(_auction.endTime <= currentTime(), "not end");

        Bids.Bid memory _lastBid = lastBidOfAuction[_auctionId];

        _auction.active = false;
        _auction.soldPrice = _lastBid.price;
        
        if (_lastBid.bidId == 0) { // no bidder
            reameNft.safeTransferFrom(address(this), _auction.owner, _auction.tokenId, "");
        } else {            
            uint256 _platformFee = feeManager.calculateFee(_auction.acceptedToken, _lastBid.price);
            uint256 _royaltyFee = reameNft.calculateRoyaltyFee(_auction.tokenId, _lastBid.price);
            uint256 _finalAmount = _lastBid.price.sub(_platformFee).sub(_royaltyFee);
            address _creator = reameNft.creatorOf(_auction.tokenId);
            address _feeCollector = feeManager.getFeeCollector();

            _sendAcceptedToken(_auction.acceptedToken, _feeCollector, _platformFee);
            _sendAcceptedToken(_auction.acceptedToken, _creator, _royaltyFee);
            _sendAcceptedToken(_auction.acceptedToken, _auction.owner, _finalAmount);

            reameNft.safeTransferFrom(address(this), _lastBid.owner, _auction.tokenId, "");
        }
        emit Claim(msg.sender, _auctionId, _lastBid.owner, _lastBid.price);
    }

    function sellTo(uint256 _auctionId) 
        external
    {
        Auctions.Auction storage _auction = auctionMap[_auctionId];
        require(_auction.active, "not active");
        require(_auction.owner == msg.sender, "permission denied");
        Bids.Bid memory _lastBid = lastBidOfAuction[_auctionId];
        require(_auction.endTime > currentTime(), "expired");

        _auction.active = false;
        _auction.soldPrice = _lastBid.price;

        if (_lastBid.bidId == 0) { // no bidder
            reameNft.safeTransferFrom(address(this), _auction.owner, _auction.tokenId, "");
        } else {            
            uint256 _platformFee = feeManager.calculateFee(_auction.acceptedToken, _lastBid.price);
            uint256 _royaltyFee = reameNft.calculateRoyaltyFee(_auction.tokenId, _lastBid.price);
            uint256 _finalAmount = _lastBid.price.sub(_platformFee).sub(_royaltyFee);
            address _creator = reameNft.creatorOf(_auction.tokenId);
            address _feeCollector = feeManager.getFeeCollector();

            _sendAcceptedToken(_auction.acceptedToken, _feeCollector, _platformFee);
            _sendAcceptedToken(_auction.acceptedToken, _creator, _royaltyFee);
            _sendAcceptedToken(_auction.acceptedToken, _auction.owner, _finalAmount);

            reameNft.safeTransferFrom(address(this), _lastBid.owner, _auction.tokenId, "");
        }

        emit SellTo(msg.sender, _auctionId, _lastBid.owner, _lastBid.price);
    }

    event SellTo(address indexed sender, uint256 indexed auctionId, address indexed recieve, uint256 price);

    function _sendAcceptedToken(
        address _acceptedToken,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_acceptedToken == address(wrapper)) {
            _sendNative(_receiver, _amount);
        } else {
            IERC20(_acceptedToken).safeTransfer(_receiver, _amount);
        }
    }

    function _sendNative(
        address _receiver,
        uint256 _amount
    ) internal {
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        require(sent, "Failed to send native");
    }

    function getAuctions()
        public view returns (Auctions.Auction[] memory _result)
    {
        _result = new Auctions.Auction[](auctions.length());
        for (uint256 i; i < auctions.length(); i++) {
            _result[i] = auctionMap[auctions.at(i)];
        }
    }

    function getAuctions(uint256 _page, uint256 _limit)
        external view returns (Auctions.Auction[] memory _result)
    {
        _result = getAuctions().paginate(_page, _limit);
    }

    function getAuctionsOf(uint256 _tokenId)
        public view returns (Auctions.Auction[] memory _result)
    {
        _result = new Auctions.Auction[](auctionsOfToken[_tokenId].length());
        for (uint256 i; i < auctionsOfToken[_tokenId].length(); i++) {
            _result[i] = auctionMap[auctionsOfToken[_tokenId].at(i)];
        }
    }

    function getAuctionsOf(uint256 _tokenId, uint256 _page, uint256 _limit)
        external view returns (Auctions.Auction[] memory _result)
    {
        _result = getAuctionsOf(_tokenId).paginate(_page, _limit);
    }

    function getBidsAt(uint256 _auctionId)
        public view returns (Bids.Bid[] memory _result)
    {
        _result = new Bids.Bid[](bids[_auctionId].length());
        for (uint256 i; i < bids[_auctionId].length(); i++) {
            _result[i] = bidMap[bids[_auctionId].at(i)];
        }
    } 

    function getBidsAt(uint256 _auctionId, uint256 _page, uint256 _limit)
        external view returns (Bids.Bid[] memory _result)
    {
        _result = getBidsAt(_auctionId).paginate(_page, _limit);
    }

    function currentTime() 
        internal virtual view returns (uint256)
    {
        return block.timestamp;
    }

    function setNativeWrapper(
        NativeWrapper _wrapper
    ) external onlyAdmin {
        require(address(_wrapper) != address(0), "invalid address");
        wrapper = _wrapper;
    }

    event Start(
        uint256 indexed auctionId,
        address indexed seller,
        uint256 indexed tokenId,
        address acceptedToken,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );

    event Bid(
        uint256 indexed bidId,
        address indexed bidder,
        uint256 indexed auctionId,
        uint256 price
    );

    event Claim(
        address indexed sender,
        uint256 indexed auctionId,
        address indexed winner,
        uint256 price
    );

    event BuyNow(
        address indexed buyer,
        uint256 indexed auctionId,
        uint256 price
    );

    event Cancel(
        uint256 indexed auctionId
    );

    event UpdateTime(
        uint256 indexed auctionId,
        uint256 startTime,
        uint256 endTime
    );

    uint256[49] private __gap;
}