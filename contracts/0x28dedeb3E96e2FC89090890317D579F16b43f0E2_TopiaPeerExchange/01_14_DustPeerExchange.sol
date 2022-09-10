// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './interfaces/INFT.sol';
import './interfaces/IWETH.sol';

contract TopiaPeerExchange is ReentrancyGuard, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    // The Metatopia ERC721 token contracts
    INFT public GENESIS;
    INFT public ALPHA;

    // The address of the WETH contract
    address public WETH;

    // The address of the TOPIA contract
    IERC20 public TOPIA;

    // The minimum percentage difference between the last offer amount and the current offer
    uint8 public minOfferIncrementPercentage;

    // The listing info
    struct Listing {
        // The address of the Lister
        address payable lister;
        // The current highest offer amount
        uint256 topiaAmount;
        // The Requested ETH for the listing
        uint256 requestedEth;
        // The time that the listing started
        uint256 startTime;
        // The time that the listing is scheduled to end
        uint256 endTime;
        // The address of the current highest offer
        address payable offerer;
        // The current offer below the requested ETH amount
        uint256 currentOffer;
        // The previous offer
        uint256 previousOffer;
        // The active offerId
        uint256 activeOfferId;
        // The number of offers placed
        uint16 numberOffers;
        // The statuses of the listing
        bool settled;
        bool canceled;
        bool failed;
    }
    mapping(uint256 => Listing) public listingId;
    uint256 private currentId = 0;
    uint256 private currentOfferId = 0;

    struct Offers {
        address offerer;
        uint256 offerAmount;
        uint256 listingId;
        uint8 offerStatus; // 1 = active, 2 = outoffer, 3 = canceled, 4 = accepted
    }
    mapping(uint256 => Offers) public offerId;
    mapping(uint256 => EnumerableSet.UintSet) listingOffers;
    mapping(address => EnumerableSet.UintSet) userOffers;
    mapping(address => EnumerableSet.UintSet) userActiveOffers;
    EnumerableSet.UintSet private activeListings;

    modifier holdsNFT() {
        require(GENESIS.balanceOf(msg.sender) > 0 || ALPHA.balanceOf(msg.sender) > 0, "Must hold a Sweeper NFT");
        _;
    }

    event ListingCreated(uint256 indexed ListingId, uint256 startTime, uint256 endTime, uint256 TopiaAmount, uint256 EthPrice);
    event OfferPlaced(uint256 indexed OfferId, uint256 indexed ListingId, address sender, uint256 value);
    event OfferCanceled(uint256 indexed OfferId, uint256 indexed ListingId, uint256 TimeStamp);
    event ListingSettled(uint256 indexed ListingId, address buyer, address seller, uint256 finalAmount, bool wasOffer, uint256 listedAmount);
    event ListingTimeBufferUpdated(uint256 timeBuffer);
    event ListingMinOfferIncrementPercentageUpdated(uint256 minOfferIncrementPercentage);
    event ListingRefunded(uint256 indexed ListingId, address Lister, uint256 TopiaRefundAmount, address Offerer, uint256 OffererRefundAmount, address Caller);
    event ListingCanceled(uint256 indexed ListingId, address Lister, uint256 TopiaAmount, uint256 TimeStamp);

    /**
     * @notice Initialize the listing house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    constructor(address _topia, address _weth, uint8 _minOfferIncrementPercentage) {
        TOPIA = IERC20(_topia);
        WETH = _weth;
        minOfferIncrementPercentage = _minOfferIncrementPercentage;
    }

    /**
     * @notice Create a offer for a Sweeper, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createOffer(uint256 _id) external payable holdsNFT nonReentrant {
        require(listingStatus(_id) == 1, 'Topia Listing is not Active');
        require(block.timestamp < listingId[_id].endTime, 'Listing expired');
        require(msg.value <= listingId[_id].requestedEth, 'Must send less than requestedEth');
        require(
            msg.value >= listingId[_id].currentOffer + ((listingId[_id].currentOffer * minOfferIncrementPercentage) / 100),
            'Must send more than last offer by minOfferIncrementPercentage amount'
        );

        address payable lastOfferer = listingId[_id].offerer;
        uint256 _offerId = currentOfferId++;

        // Refund the last offerer, if applicable
        if (lastOfferer != address(0)) {
            userActiveOffers[lastOfferer].remove(listingId[_id].activeOfferId);
            if(userActiveOffers[lastOfferer].length() == 0) {
                _safeTransferETHWithFallback(lastOfferer, listingId[_id].currentOffer);
            }
            
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
            listingId[_id].previousOffer = listingId[_id].currentOffer;
        }

        listingId[_id].currentOffer = msg.value;
        listingId[_id].offerer = payable(msg.sender);
        listingId[_id].activeOfferId = _offerId;
        listingOffers[_id].add(_offerId);
        listingId[_id].numberOffers++;
        offerId[_offerId].offerer = msg.sender;
        offerId[_offerId].offerAmount = msg.value;
        offerId[_offerId].listingId = _id;
        offerId[_offerId].offerStatus = 1;
        userOffers[msg.sender].add(_offerId);
        userActiveOffers[msg.sender].add(_offerId);

        emit OfferPlaced(_offerId, _id, msg.sender, msg.value);
    }

    function cancelOffer(uint256 _id, uint256 _offerId) external nonReentrant {
        require(offerId[_offerId].offerer == msg.sender, "Caller is not Offerer");
        require(offerId[_offerId].listingId == _id && listingId[_id].activeOfferId == _offerId, "IDs do not match");
        require(listingStatus(_id) == 1, "Topia Listing is not Active");
        require(offerId[_offerId].offerStatus == 1, "Offer is not active");

        _safeTransferETHWithFallback(payable(msg.sender), offerId[_offerId].offerAmount);
        offerId[listingId[_id].activeOfferId].offerStatus = 3;
        listingId[_id].currentOffer = listingId[_id].previousOffer;
        listingId[_id].offerer = payable(address(0));
        listingId[_id].activeOfferId = 0;

        emit OfferCanceled(_offerId, _id, block.timestamp);
    }

    /**
     * @notice Set the listing minimum offer increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinOfferIncrementPercentage(uint8 _minOfferIncrementPercentage) external onlyOwner {
        minOfferIncrementPercentage = _minOfferIncrementPercentage;

        emit ListingMinOfferIncrementPercentageUpdated(_minOfferIncrementPercentage);
    }

    /**
     * @notice Create a Listing.
     * @dev Store the listing details in the `listingId` state variable and emit an ListingCreated event.
     */
    function _createListing(uint256 _topiaAmount, uint256 _requestedEth, uint256 _endTime) external holdsNFT nonReentrant {
        uint256 startTime = block.timestamp;
        uint256 _listingId = currentId++;

        listingId[_listingId] = Listing({
            lister : payable(msg.sender),
            topiaAmount : _topiaAmount,
            requestedEth : _requestedEth,
            startTime : startTime,
            endTime : _endTime,
            offerer : payable(address(0)),
            currentOffer : 0,
            previousOffer : 0,
            activeOfferId : 0,
            numberOffers : 0,
            settled : false,
            canceled : false,
            failed : false
        });

        activeListings.add(_listingId);

        TOPIA.safeTransferFrom(msg.sender, address(this), _topiaAmount);

        emit ListingCreated(_listingId, startTime, _endTime, _topiaAmount, _requestedEth);
    }

    function cancelListing(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can cancel");
        require(listingStatus(_id) == 1, "Listing is not active");
        listingId[_id].canceled = true;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
            offerId[listingId[_id].activeOfferId].offerStatus = 3;
        }
        activeListings.remove(_id);
        TOPIA.safeTransfer(listingId[_id].lister, listingId[_id].topiaAmount);

        emit ListingCanceled(_id, listingId[_id].lister, listingId[_id].topiaAmount, block.timestamp);
        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].topiaAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    /**
     * @notice Settle a listing to high offerer and paying out to the lister.
     */
    function acceptOffer(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can accept offer");
        require(listingStatus(_id) == 1, "Listing has already been settled or canceled");
        require(block.timestamp <= listingId[_id].endTime, "Listing has expired");
        require(listingId[_id].offerer != address(0), "No active Offerer");
        require(offerId[listingId[_id].activeOfferId].offerStatus == 1, "Offer is not active");

        listingId[_id].settled = true;
        activeListings.remove(_id);

        TOPIA.safeTransfer(listingId[_id].offerer, listingId[_id].topiaAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, listingId[_id].currentOffer);
        offerId[listingId[_id].activeOfferId].offerStatus = 4;

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].currentOffer, true, listingId[_id].requestedEth);
    }

    function buyNow(uint256 _id) external holdsNFT nonReentrant {
        require(listingStatus(_id) == 1, 'Listing has already been settled or canceled');
        require(block.timestamp <= listingId[_id].endTime, 'Listing has expired');

        listingId[_id].settled = true;
        activeListings.remove(_id);

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
        }

        TOPIA.safeTransfer(msg.sender, listingId[_id].topiaAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, listingId[_id].currentOffer);

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].currentOffer, false, listingId[_id].requestedEth);
    }

    function claimRefundOnExpire(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister || msg.sender == listingId[_id].offerer, 'Only Lister can accept offer');
        require(listingStatus(_id) == 3, 'Listing has not expired');
        listingId[_id].failed = true;
        activeListings.remove(_id);

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
        }
        TOPIA.safeTransfer(listingId[_id].lister, listingId[_id].topiaAmount);

        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].topiaAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    function listingStatus(uint256 _id) public view returns (uint8) {
        if (listingId[_id].canceled) {
        return 3; // CANCELED - Lister canceled
        }
        if ((block.timestamp > listingId[_id].endTime) && !listingId[_id].settled) {
        return 3; // FAILED - not sold by end time
        }
        if (listingId[_id].settled) {
        return 2; // SUCCESS - hardcap met
        }
        if ((block.timestamp <= listingId[_id].endTime) && !listingId[_id].settled) {
        return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getOffersByListingId(uint256 _id) external view returns (uint256[] memory offerIds) {
        uint256 length = listingOffers[_id].length();
        offerIds = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = listingOffers[_id].at(i);
        }
    }

    function getOffersByUser(address _user) external view returns (uint256[] memory offerIds) {
        uint256 length = userOffers[_user].length();
        offerIds = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = userOffers[_user].at(i);
        }
    }

    function getTotalOffersLength() external view returns (uint256) {
        return currentOfferId;
    }

    function getOffersLengthForListing(uint256 _id) external view returns (uint256) {
        return listingOffers[_id].length();
    }

    function getOffersLengthForUser(address _user) external view returns (uint256) {
        return userOffers[_user].length();
    }

    function getOfferInfoByIndex(uint256 _offerId) external view returns (address _offerer, uint256 _offerAmount, uint256 _listingId, string memory _offerStatus) {
        _offerer = offerId[_offerId].offerer;
        _offerAmount = offerId[_offerId].offerAmount;
        _listingId = offerId[_offerId].listingId;
        if(offerId[_offerId].offerStatus == 1) {
            _offerStatus = 'active';
        } else if(offerId[_offerId].offerStatus == 2) {
            _offerStatus = 'outoffer';
        } else if(offerId[_offerId].offerStatus == 3) {
            _offerStatus = 'canceled';
        } else if(offerId[_offerId].offerStatus == 4) {
            _offerStatus = 'accepted';
        } else {
            _offerStatus = 'invalid OfferID';
        }
    }

    function getActiveListings() external view returns (uint256[] memory _activeListings) {
        uint256 length = activeListings.length();
        _activeListings = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            _activeListings[i] = activeListings.at(i);
        }
    }

    function getAllListings() external view returns (uint256[] memory listings, uint256[] memory status) {
        listings = new uint256[](currentId);
        status = new uint256[](currentId);
        for(uint i = 1; i <= currentId; i++) {
            listings[i - 1] = i;
            status[i - 1] = listingStatus(i);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(WETH).deposit{ value: amount }();
            IERC20(WETH).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}