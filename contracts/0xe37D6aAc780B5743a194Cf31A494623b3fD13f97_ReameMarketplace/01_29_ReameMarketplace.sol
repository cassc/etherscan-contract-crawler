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
import "./libraries/Offers.sol";
import "./libraries/Listings.sol";
import "./libraries/Uint256Pagination.sol";
import "./NativeWrapper.sol";

contract ReameMarketplace is AccessControlUpgradeable, ERC721HolderUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Offers for Offers.Offer;
    using Offers for Offers.Offer[];
    using Listings for Listings.Listing;
    using Listings for Listings.Listing[];
    using Uint256Pagination for uint256[];

    modifier onlyAdmin 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    IFeeManager public feeManager;
    IReameNFT public reameNft;    

    Counters.Counter private _listingIdTracker;
    Counters.Counter private _offerIdTracker;

    // token id => accpeted token => [listing id]
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private listings;

    // token id => accpeted token => [offer id]
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private offers;

    // user address => [listing id]
    mapping(address => EnumerableSet.UintSet) private userListings;

    // user address => [offer id]
    mapping(address => EnumerableSet.UintSet) private userOffers;

    // token id => accepted token => current price
    mapping(uint256 => mapping(address => uint256)) public currentPrice;

    // listing id => Listing
    mapping(uint256 => Listings.Listing) public listingMap;

    // offer id => Offer
    mapping(uint256 => Offers.Offer) public offerMap;

    NativeWrapper public wrapper;

    receive() external payable {}

    function initialize(address _admin, address _feeManager, address _reameNft) 
        public initializer
    {
        __AccessControl_init_unchained();
        __ERC721Holder_init_unchained();
        __ReameMarketplace_init_unchained(_admin, _feeManager, _reameNft);
    }

    function __ReameMarketplace_init_unchained(address _admin, address _feeManager, address _reameNft)
        internal initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        feeManager = IFeeManager(_feeManager);
        reameNft = IReameNFT(_reameNft);        
        _listingIdTracker.increment(); // start at id = 1
        _offerIdTracker.increment();   // start at id = 1
    }

    function sell(
        uint256 _tokenId, 
        address _acceptedToken, 
        uint256 _price, 
        uint256 _startTime, 
        uint256 _endTime)
        public returns (uint256 _listingId)
    {
        require(reameNft.ownerOf(_tokenId) == msg.sender, "not owner token");
        require(_endTime > _startTime, "invalid time");
        require(_price != 0, "invalid price");
        require(_acceptedToken != address(0), "invalid accepted token");

        _listingId = _listingIdTracker.current();
        listingMap[_listingId] = Listings.Listing({
            listingId: _listingId,
            owner: msg.sender,
            tokenId: _tokenId,
            acceptedToken: _acceptedToken,
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            active: true
        });
        listings[_tokenId][_acceptedToken].add(_listingId);
        userListings[msg.sender].add(_listingId);

        _listingIdTracker.increment();
        
        reameNft.safeTransferFrom(msg.sender, address(this), _tokenId, "");

        emit Sell(_listingId, msg.sender, _tokenId, _acceptedToken, _price, _startTime, _endTime);
    }

    function cancelListing(uint256 _listingId)
        external
    {
        Listings.Listing storage _listing = listingMap[_listingId];
        require(_listing.owner == msg.sender, "no permission");
        require(_listing.active, "not active");
        
        _listing.active = false;
        userListings[msg.sender].remove(_listingId);
        listings[_listing.tokenId][_listing.acceptedToken].remove(_listingId);
        reameNft.safeTransferFrom(address(this), msg.sender, _listing.tokenId, "");

        emit CancelListing(_listingId, msg.sender);
    }

    function buyAt(uint256 _listingId)
        payable external
    {
        Listings.Listing storage _listing = listingMap[_listingId];
        require(_listing.active, "not active");
        require(_listing.endTime >= currentTime(), "already expired");
        require(_listing.owner != msg.sender, "same account");

        _listing.active = false;
        userListings[_listing.owner].remove(_listingId);
        listings[_listing.tokenId][_listing.acceptedToken].remove(_listingId);
        
        currentPrice[_listing.tokenId][_listing.acceptedToken] = _listing.price;

        uint256 _buyValue = _listing.price;
        uint256 _platformFee = feeManager.calculateFee(_listing.acceptedToken, _buyValue);
        uint256 _royaltyFee = reameNft.calculateRoyaltyFee(_listing.tokenId, _buyValue);
        uint256 _finalAmount = _buyValue.sub(_platformFee).sub(_royaltyFee);
        address _creator = reameNft.creatorOf(_listing.tokenId);
        address _feeCollector = feeManager.getFeeCollector();

        if (_listing.acceptedToken == address(wrapper)) {
            require(msg.value >= _buyValue, "not enough native");
            payable(_feeCollector).transfer(_platformFee);
            payable(_creator).transfer(_royaltyFee);
            payable(_listing.owner).transfer(_finalAmount);
        } else {
            IERC20(_listing.acceptedToken).safeTransferFrom(msg.sender, _feeCollector, _platformFee);
            IERC20(_listing.acceptedToken).safeTransferFrom(msg.sender, _creator, _royaltyFee);
            IERC20(_listing.acceptedToken).safeTransferFrom(msg.sender, _listing.owner, _finalAmount);
        }
        
        reameNft.safeTransferFrom(address(this), msg.sender, _listing.tokenId, "");

        emit BuyAt(_listingId, msg.sender);
    }

    function offer(
        uint256 _tokenId, 
        address _acceptedToken, 
        uint256 _price, 
        uint256 _startTime, 
        uint256 _endTime
    ) payable public returns (uint256) {
        require(reameNft.exists(_tokenId), "not exitst");
        require(_endTime > _startTime, "invalid time");
        require(_price != 0, "invalid price");
        require(_acceptedToken != address(0), "invalid accepted token");

        uint256 _offerId = _offerIdTracker.current();
        offerMap[_offerId] = Offers.Offer({
            offerId: _offerId,
            owner: msg.sender,
            tokenId: _tokenId,
            acceptedToken: _acceptedToken,
            price: _price,
            startTime: _startTime,
            endTime: _endTime,
            active: true
        });
        offers[_tokenId][_acceptedToken].add(_offerId);
        userOffers[msg.sender].add(_offerId);

        _offerIdTracker.increment();

        uint256 _wantToBuyValue = _price;

        if (_acceptedToken == address(wrapper)) {
            require(msg.value >= _wantToBuyValue, "not enough native");
        } else {
            IERC20(_acceptedToken).safeTransferFrom(msg.sender, address(this), _wantToBuyValue);
        }
        

        emit Offer(_offerId, msg.sender, _tokenId, _acceptedToken, _price, _startTime, _endTime);

        return _offerId;
    }

    function cancelOffer(uint256 _offerId)
        external
    {
        Offers.Offer storage _offer = offerMap[_offerId];
        require(_offer.owner == msg.sender, "no permission");
        require(_offer.active, "not active");

        _offer.active = false;
        userOffers[msg.sender].remove(_offerId);
        offers[_offer.tokenId][_offer.acceptedToken].remove(_offerId);

        _sendAcceptedToken(_offer.acceptedToken, msg.sender, _offer.price);
        
        emit CancelOffer(_offerId, msg.sender);
    }

    function sellTo(uint256 _offerId)
        external
    {
        Offers.Offer storage _offer = offerMap[_offerId];
        require(_offer.active, "not active");
        require(_offer.endTime >= currentTime(), "already expired");
        require(_offer.owner != msg.sender, "same account");

        _offer.active = false;
        userOffers[_offer.owner].remove(_offerId);
        offers[_offer.tokenId][_offer.acceptedToken].remove(_offerId);

        currentPrice[_offer.tokenId][_offer.acceptedToken] = _offer.price;

        uint256 _sellValue = _offer.price;
        uint256 _platformFee = feeManager.calculateFee(_offer.acceptedToken, _sellValue);        
        uint256 _royaltyFee = reameNft.calculateRoyaltyFee(_offer.tokenId, _sellValue);
        uint256 _finalAmount = _sellValue.sub(_platformFee).sub(_royaltyFee);
        address _creator = reameNft.creatorOf(_offer.tokenId);
        address _feeCollector = feeManager.getFeeCollector();

        _sendAcceptedToken(_offer.acceptedToken, _feeCollector, _platformFee);
        _sendAcceptedToken(_offer.acceptedToken, _creator, _royaltyFee);
        _sendAcceptedToken(_offer.acceptedToken, msg.sender, _finalAmount);

        reameNft.safeTransferFrom(msg.sender, _offer.owner, _offer.tokenId, "");

        emit SellTo(_offerId, msg.sender);
    }

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

    function getOffersAt(uint256 _tokenId, address _acceptedToken)
        public view returns (Offers.Offer[] memory _result)
    {
        EnumerableSet.UintSet storage _offerIds = offers[_tokenId][_acceptedToken];
        _result = new Offers.Offer[](_offerIds.length());
        for(uint256 i; i < _offerIds.length(); i++) {
            _result[i] = offerMap[_offerIds.at(i)];
        }
    }

    function getOfferAt(uint256 _tokenId, address _acceptedToken, uint256 _page, uint256 _limit)
        public view returns (Offers.Offer[] memory _result)
    {
        _result = getOffersAt(_tokenId, _acceptedToken).paginate(_page, _limit);
    }

    function getOffersOf(address _user)
        public view returns (Offers.Offer[] memory _result)
    {
        _result = new Offers.Offer[](userOffers[_user].length());
        for(uint256 i; i < userOffers[_user].length(); i++) {
            _result[i] = offerMap[userOffers[_user].at(i)];
        }
    }

    function getOffersOf(address _user, uint256 _page, uint256 _limit)
        external view returns (Offers.Offer[] memory _result)
    {
        _result = getOffersOf(_user).paginate(_page, _limit);
    }

    function getListingsAt(uint256 _tokenId, address _acceptedToken)
        public view returns (Listings.Listing[] memory _result)
    {
        EnumerableSet.UintSet storage _listingIds = listings[_tokenId][_acceptedToken];
        _result = new Listings.Listing[](_listingIds.length());
        for(uint256 i; i < _listingIds.length(); i++) {
            _result[i] = listingMap[_listingIds.at(i)];
        }
    }

    function getListingsAt(uint256 _tokenId, address _acceptedToken, uint256 _page, uint256 _limit)
        external view returns (Listings.Listing[] memory _result)
    {
        _result = getListingsAt(_tokenId, _acceptedToken).paginate(_page, _limit);
    }

    function getListingsOf(address _user)
        public view returns (Listings.Listing[] memory _result)
    {
        _result = new Listings.Listing[](userListings[_user].length());
        for(uint256 i; i < userListings[_user].length(); i++) {
            _result[i] = listingMap[userListings[_user].at(i)];
        }
    }

    function getListingsOf(address _user, uint256 _page, uint256 _limit)
        external view returns (Listings.Listing[] memory _result)
    {
        _result = getListingsOf(_user).paginate(_page, _limit);
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

    event Sell(
        uint256 indexed listingId,
        address indexed seller,
        uint256 indexed tokenId,
        address acceptedToken,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );

    event Offer(
        uint256 indexed offerId,
        address indexed buyer,
        uint256 indexed tokenId,
        address acceptedToken,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );    

    event CancelListing(
        uint256 indexed listingId,
        address indexed seller
    );

    event CancelOffer(
        uint256 indexed offerId,
        address indexed buyer
    );

    event BuyAt(
        uint256 indexed listingId,
        address indexed buyer
    );

    event SellTo(
        uint256 indexed offerId,
        address indexed seller
    );

    uint256[49] private __gap;
}