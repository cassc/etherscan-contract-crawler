// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/INFT.sol';
import './interfaces/IWETH.sol';

contract DustPeerExchange is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // The Metadust ERC721 token contracts
    INFT public SWEEPERS;

    // The address of the WETH contract
    address public WETH;

    // The address of the DUST contract
    IERC20 public DUST;

    // The minimum percentage difference between the last offer amount and the current offer
    uint16 public minOfferIncrementPercentage;
    
    // The minimum listing and offer variables
    uint256 private MinListPrice;
    uint16 public minOfferPercent;

    // Restriction Bools
    bool public isPaused;
    bool public allListersAllowed = true;
    bool public allBuyersAllowed = true;
    bool public allOfferersAllowed = true;

    // The listing info
    struct Listing {
        // The address of the Lister
        address payable lister;
        // The time that the listing started
        uint32 startTime;
        // The time that the listing is scheduled to end
        uint32 endTime;
        // The current highest offer amount
        uint256 dustAmount;
        // The Requested ETH for the listing
        uint256 requestedEth;  
        // The current offer below the requested ETH amount
        uint256 currentOffer;
        // The previous offer
        uint256 previousOffer;
        // The active offerId
        uint32 activeOfferId;
        // The address of the current highest offer
        address payable offerer;
        // The number of offers placed
        uint16 numberOffers;
        // The statuses of the listing
        bool settled;
        bool canceled;
        bool failed;
    }
    mapping(uint32 => Listing) public listingId;
    uint32 private currentId = 1;
    uint32 private currentOfferId = 1;
    mapping(uint32 => uint32[]) public allListingOfferIds;

    struct Offers {
        address offerer;
        uint8 offerStatus; // 1 = active, 2 = outoffer, 3 = canceled, 4 = accepted
        uint32 listingId;
        uint256 offerAmount;
    }
    mapping(uint32 => Offers) public offerId;
    mapping(address => uint32[]) userOffers;
    uint32 public activeListingCount;

    uint16 public tax;
    address payable public taxWallet;

    modifier holdsNFTLister() {
        require(allListersAllowed || SWEEPERS.balanceOf(msg.sender) > 0, "Must hold a Metadust NFT");
        _;
    }

    modifier holdsNFTBuyer() {
        require(allBuyersAllowed || SWEEPERS.balanceOf(msg.sender) > 0, "Must hold a Metadust NFT");
        _;
    }

    modifier holdsNFTOfferer() {
        require(allOfferersAllowed || SWEEPERS.balanceOf(msg.sender) > 0, "Must hold a Metadust NFT");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Contract is Paused to new listings");
        _;
    }

    event ListingCreated(uint256 indexed ListingId, uint256 startTime, uint256 endTime, uint256 DustAmount, uint256 EthPrice);
    event ListingEdited(uint256 indexed ListingId, uint256 EthPrice, uint256 endTime);
    event OfferPlaced(uint256 indexed OfferId, uint256 indexed ListingId, address sender, uint256 value);
    event OfferCanceled(uint256 indexed OfferId, uint256 indexed ListingId, uint256 TimeStamp);
    event ListingSettled(uint256 indexed ListingId, address Buyer, address Seller, uint256 FinalAmount, uint256 TaxAmount, bool wasOffer, uint256 listedAmount);
    event ListingTimeBufferUpdated(uint256 timeBuffer);
    event ListingMinOfferIncrementPercentageUpdated(uint256 minOfferIncrementPercentage);
    event ListingRefunded(uint256 indexed ListingId, address Lister, uint256 DustRefundAmount, address Offerer, uint256 OffererRefundAmount, address Caller);
    event ListingCanceled(uint256 indexed ListingId, address Lister, uint256 DustAmount, uint256 TimeStamp);
    event Received(address indexed From, uint256 Amount);

    /**
     * @notice Initialize the listing house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    constructor(
        address _dust, 
        address _weth, 
        address _sweepers, 
        uint16 _minOfferIncrementPercentage, 
        uint256 _minListPrice, 
        uint16 _minOfferPercent, 
        address payable _taxWallet, 
        uint16 _tax
    ) {
        DUST = IERC20(_dust);
        WETH = _weth;
        SWEEPERS = INFT(_sweepers);
        minOfferIncrementPercentage = _minOfferIncrementPercentage;
        MinListPrice = _minListPrice;
        minOfferPercent = _minOfferPercent;
        taxWallet = _taxWallet;
        tax = _tax;
    }

    /**
     * @notice Set the listing minimum offer increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinOfferIncrementPercentage(uint16 _minOfferIncrementPercentage) external onlyOwner {
        minOfferIncrementPercentage = _minOfferIncrementPercentage;

        emit ListingMinOfferIncrementPercentageUpdated(_minOfferIncrementPercentage);
    }

    function setPaused(bool _flag) external onlyOwner {
        isPaused = _flag;
    }

    function setListersAllowed(bool _flag) external onlyOwner {
        allListersAllowed = _flag;
    }

    function setBuyersAllowed(bool _flag) external onlyOwner {
        allBuyersAllowed = _flag;
    }

    function setOfferersAllowed(bool _flag) external onlyOwner {
        allOfferersAllowed = _flag;
    }

    function setTax(address payable _taxWallet, uint16 _tax) external onlyOwner {
        taxWallet = _taxWallet;
        tax = _tax;
    }

    function setMinListPrice(uint256 _minListPrice) external onlyOwner {
        MinListPrice = _minListPrice;
    }

    function setMinOfferPercent(uint16 _percent) external onlyOwner {
        minOfferPercent = _percent;
    }

    function createListing(uint256 _dustAmount, uint256 _requestedEth, uint32 _endTime) external notPaused holdsNFTLister nonReentrant {
        require((_requestedEth * 10**9) / _dustAmount >= minListPrice(), "Listing Price too low");
        uint32 startTime = uint32(block.timestamp);
        uint32 _listingId = currentId++;

        listingId[_listingId].lister = payable(msg.sender);
        listingId[_listingId].dustAmount = _dustAmount;
        listingId[_listingId].requestedEth = _requestedEth;
        listingId[_listingId].startTime = startTime;
        listingId[_listingId].endTime = _endTime;
        activeListingCount++;

        DUST.safeTransferFrom(msg.sender, address(this), _dustAmount);

        emit ListingCreated(_listingId, startTime, _endTime, _dustAmount, _requestedEth);
    }

    function cancelListing(uint32 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can cancel");
        require(listingStatus(_id) == 1, "Listing is not active");
        listingId[_id].canceled = true;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
            offerId[listingId[_id].activeOfferId].offerStatus = 3;
        }
        activeListingCount--;
        DUST.safeTransfer(listingId[_id].lister, listingId[_id].dustAmount);

        emit ListingCanceled(_id, listingId[_id].lister, listingId[_id].dustAmount, block.timestamp);
        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].dustAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    function editListingPrice(uint32 _id, uint256 _requestedEth) external notPaused nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can edit");
        require(listingStatus(_id) == 1, "Listing is not active");
        require((_requestedEth * 10**9) / listingId[_id].dustAmount >= minListPrice(), "Listing Price too low");
        require(_requestedEth > listingId[_id].currentOffer, "Has offer higher than new price");

        listingId[_id].requestedEth = _requestedEth;

        emit ListingEdited(_id, _requestedEth, listingId[_id].endTime);
    }

    function editListingEndTime(uint32 _id, uint32 _newEndTime) external notPaused nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can edit");
        require(listingStatus(_id) == 1, "Listing is not active");
        require(_newEndTime > block.timestamp, "End time already passed");

        listingId[_id].endTime = _newEndTime;

        emit ListingEdited(_id, listingId[_id].requestedEth, _newEndTime);
    }

    /**
     * @notice Create a offer for DUST, with a given ETH amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createOffer(uint32 _id) external payable holdsNFTOfferer nonReentrant {
        require(listingStatus(_id) == 1, 'Dust Listing is not Active');
        require(block.timestamp < listingId[_id].endTime, 'Listing expired');
        require(msg.value <= listingId[_id].requestedEth, 'Must offer less than requestedEth');
        require(msg.value >= listingId[_id].requestedEth * minOfferPercent / 10000, 'Must offer more than minimum offer amount');
        require(
            msg.value >= listingId[_id].currentOffer + ((listingId[_id].currentOffer * minOfferIncrementPercentage) / 10000),
            'Must send more than last offer by minOfferIncrementPercentage amount'
        );
        require(msg.sender != listingId[_id].lister, 'Lister not allowed to Offer');

        address payable lastOfferer = listingId[_id].offerer;
        uint32 _offerId = currentOfferId++;

        // Refund the last offerer, if applicable
        if (lastOfferer != address(0)) {
            _safeTransferETHWithFallback(lastOfferer, listingId[_id].currentOffer);  
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
            listingId[_id].previousOffer = listingId[_id].currentOffer;
        }

        listingId[_id].currentOffer = msg.value;
        listingId[_id].offerer = payable(msg.sender);
        listingId[_id].activeOfferId = _offerId;
        listingId[_id].numberOffers++;
        allListingOfferIds[_id].push(_offerId);
        offerId[_offerId].offerer = msg.sender;
        offerId[_offerId].offerAmount = msg.value;
        offerId[_offerId].listingId = _id;
        offerId[_offerId].offerStatus = 1;
        userOffers[msg.sender].push(_offerId);

        emit OfferPlaced(_offerId, _id, msg.sender, msg.value);
    }

    function cancelOffer(uint32 _id, uint32 _offerId) external nonReentrant {
        require(offerId[_offerId].offerer == msg.sender, "Caller is not Offerer");
        require(offerId[_offerId].listingId == _id && listingId[_id].activeOfferId == _offerId, "IDs do not match");
        require(listingStatus(_id) == 1, "Dust Listing is not Active");
        require(offerId[_offerId].offerStatus == 1, "Offer is not active");

        _safeTransferETHWithFallback(payable(msg.sender), offerId[_offerId].offerAmount);
        offerId[listingId[_id].activeOfferId].offerStatus = 3;
        listingId[_id].currentOffer = listingId[_id].previousOffer;
        listingId[_id].offerer = payable(address(0));
        listingId[_id].activeOfferId = 0;

        emit OfferCanceled(_offerId, _id, block.timestamp);
    }

    /**
     * @notice Settle a listing to high offerer and paying out to the lister.
     */
    function acceptOffer(uint32 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can accept offer");
        require(listingStatus(_id) == 1 && !listingId[_id].settled, "Listing has already been settled or canceled");
        require(block.timestamp <= listingId[_id].endTime, "Listing has expired");
        require(listingId[_id].offerer != address(0), "No active Offerer");
        require(offerId[listingId[_id].activeOfferId].offerStatus == 1, "Offer is not active");

        listingId[_id].settled = true;
        activeListingCount--;

        uint256 taxAmount = listingId[_id].currentOffer * tax / 10000;
        uint256 finalEthAmount = listingId[_id].currentOffer - taxAmount;

        DUST.safeTransfer(listingId[_id].offerer, listingId[_id].dustAmount);
        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, finalEthAmount);
        offerId[listingId[_id].activeOfferId].offerStatus = 4;

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].currentOffer, taxAmount, true, listingId[_id].requestedEth);
    }

    function buyNow(uint32 _id) external payable holdsNFTBuyer nonReentrant {
        require(listingStatus(_id) == 1 && !listingId[_id].settled, 'Listing has already been settled or canceled');
        require(block.timestamp <= listingId[_id].endTime, 'Listing has expired');
        require(msg.value == listingId[_id].requestedEth, 'ETH Value must be equal to listing price');

        listingId[_id].settled = true;
        activeListingCount--;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
        }

        uint256 taxAmount = listingId[_id].requestedEth * tax / 10000;
        uint256 finalEthAmount = listingId[_id].requestedEth - taxAmount;

        DUST.safeTransfer(msg.sender, listingId[_id].dustAmount);
        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, finalEthAmount);

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].requestedEth, taxAmount, false, listingId[_id].requestedEth);
    }

    function claimRefundOnExpire(uint32 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister || msg.sender == listingId[_id].offerer || msg.sender == owner(), 'Only Lister can accept offer');
        require(listingStatus(_id) == 3, 'Listing has not expired');
        require(!listingId[_id].failed && !listingId[_id].canceled, 'Refund already claimed');
        listingId[_id].failed = true;
        activeListingCount--;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
        }
        DUST.safeTransfer(listingId[_id].lister, listingId[_id].dustAmount);

        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].dustAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    function emergencyCancelListing(uint32 _id) external nonReentrant onlyOwner {
        require(listingStatus(_id) == 1, "Listing is not active");
        listingId[_id].canceled = true;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
            offerId[listingId[_id].activeOfferId].offerStatus = 3;
        }
        activeListingCount--;
        DUST.safeTransfer(listingId[_id].lister, listingId[_id].dustAmount);

        emit ListingCanceled(_id, listingId[_id].lister, listingId[_id].dustAmount, block.timestamp);
        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].dustAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    function listingStatus(uint32 _id) public view returns (uint8) {
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

    function getOffersByListingId(uint32 _id) external view returns (uint32[] memory offerIds) {
        uint256 length = allListingOfferIds[_id].length;
        offerIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = allListingOfferIds[_id][i];
        }
    }

    function getOffersByUser(address _user) external view returns (uint32[] memory offerIds) {
        uint256 length = userOffers[_user].length;
        offerIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = userOffers[_user][i];
        }
    }

    function getTotalOffersLength() external view returns (uint32) {
        return currentOfferId;
    }

    function getOffersLengthForListing(uint32 _id) external view returns (uint256) {
        return allListingOfferIds[_id].length;
    }

    function getOffersLengthForUser(address _user) external view returns (uint256) {
        return userOffers[_user].length;
    }

    function getOfferInfoByIndex(uint32 _offerId) external view returns (address _offerer, uint256 _offerAmount, uint32 _listingId, string memory _offerStatus) {
        _offerer = offerId[_offerId].offerer;
        _offerAmount = offerId[_offerId].offerAmount;
        _listingId = offerId[_offerId].listingId;
        if(offerId[_offerId].offerStatus == 1) {
            _offerStatus = 'active';
        } else if(offerId[_offerId].offerStatus == 2) {
            _offerStatus = 'outOffered';
        } else if(offerId[_offerId].offerStatus == 3) {
            _offerStatus = 'canceled';
        } else if(offerId[_offerId].offerStatus == 4) {
            _offerStatus = 'accepted';
        } else {
            _offerStatus = 'invalid OfferID';
        }
    }

    function getOfferStatus(uint32 _offerId) external view returns (string memory _offerStatus) {
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

    function getAllActiveListings() external view returns (uint32[] memory _activeListings) {
        uint256 length = activeListingCount;
        _activeListings = new uint32[](length);
        uint32 z = 0;
        for(uint32 i = 1; i <= currentId; i++) {
            if(listingStatus(i) == 1) {
                _activeListings[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    function getAllListings() external view returns (uint32[] memory listings, uint8[] memory status) {
        listings = new uint32[](currentId);
        status = new uint8[](currentId);
        for(uint32 i = 1; i < currentId; i++) {
            listings[i - 1] = i;
            status[i - 1] = listingStatus(i);
        }
    }

    function minListPrice() public view returns (uint256) {
        return MinListPrice;
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

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}