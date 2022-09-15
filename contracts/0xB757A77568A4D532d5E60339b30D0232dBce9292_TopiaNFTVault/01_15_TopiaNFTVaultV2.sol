// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/ITOPIA.sol';
import './interfaces/INFT.sol';
import './interfaces/IHUB.sol';


contract TopiaNFTVault is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    // The ERC721 token contracts
    INFT public ALPHA;
    INFT public GENESIS;
    INFT public RATS;
    IHUB public HUB;

    // The address of the DUST contract
    ITOPIA public TOPIA;

    address public sweepersTreasury;

    // The minimum amount of time left in an auction after a new bid is created
    uint32 public timeBufferThreshold;
    // The amount of time to add to the auction when a bid is placed under the timeBufferThreshold
    uint32 public timeBuffer;

    // The minimum percentage difference between the last bid amount and the current bid
    uint16 public minBidIncrementPercentage;

    address payable public Dev;
    uint256 public DevFee = 0.0005 ether;

    // The auction info
    struct Auction {
        // The Contract Address for the listed NFT
        INFT contractAddress;
        // The Token ID for the listed NFT
        uint16 tokenId;
        // The time that the auction started
        uint32 startTime;
        // The time that the auction is scheduled to end
        uint32 endTime;
        // The opening price for the auction
        uint256 startingPrice;
        // The current bid amount in DUST
        uint256 currentBid;
        // The previous bid amount in DUST
        uint256 previousBid;
        // The active bidId
        uint32 activeBidId;
        // The address of the current highest bid
        address bidder;
        // The number of bids placed
        uint16 numberBids;
        // The statuses of the auction
        bool blind;
        bool settled;
        bool failed;
        string hiddenImage;
    }
    mapping(uint32 => Auction) public auctionId;
    uint32 private currentAuctionId = 0;
    uint32 private currentBidId = 0;
    uint32 public activeAuctionCount;

    struct Bids {
        uint256 bidAmount;
        address bidder;
        uint32 auctionId;
        uint8 bidStatus; // 1 = active, 2 = outbid, 3 = canceled, 4 = accepted
    }
    mapping(uint32 => Bids) public bidId;
    mapping(uint32 => uint32[]) public auctionBids;
    mapping(address => uint32[]) public userBids;
    bool public mustHold;

    modifier holdsMetatopia() {
        require(!mustHold || ALPHA.balanceOf(msg.sender) > 0 || GENESIS.balanceOf(msg.sender) > 0 || RATS.balanceOf(msg.sender) > 0 || HUB.balanceOf(msg.sender) > 0, "Must hold a Sweeper NFT");
        _;
    }

    modifier onlySweepersTreasury() {
        require(msg.sender == sweepersTreasury || msg.sender == owner(), "Sender not allowed");
        _;
    }

    event AuctionCreated(uint32 indexed AuctionId, uint32 startTime, uint32 endTime, address indexed NFTContract, uint16 indexed TokenId, bool BlindAuction);
    event AuctionSettled(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID, address buyer, uint256 finalAmount);
    event AuctionFailed(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID);
    event AuctionCanceled(uint32 indexed AuctionId, address indexed NFTProjectAddress, uint16 tokenID);
    event AuctionExtended(uint32 indexed AuctionId, uint32 NewEndTime);
    event AuctionTimeBufferUpdated(uint32 timeBuffer);
    event AuctionMinBidIncrementPercentageUpdated(uint16 minBidIncrementPercentage);
    event BidPlaced(uint32 indexed BidId, uint32 indexed AuctionId, address sender, uint256 value);

    constructor(
        // address _alpha,
        // address _genesis,
        // address _rats,
        // address _hub,
        address _topia,
        uint32 _timeBuffer,
        uint16 _minBidIncrementPercentage
    ) {
        // ALPHA = INFT(_alpha);
        // GENESIS = INFT(_genesis);
        // RATS = INFT(_rats);
        // HUB = IHUB(_hub);
        TOPIA = ITOPIA(_topia);
        timeBuffer = _timeBuffer;
        timeBufferThreshold = _timeBuffer;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint32 _timeBufferThreshold, uint32 _timeBuffer) external onlyOwner {
        require(timeBuffer >= timeBufferThreshold, 'timeBuffer must be >= timeBufferThreshold');
        timeBufferThreshold = _timeBufferThreshold;
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    function setDev(address _dev, uint256 _devFee) external onlyOwner {
        Dev = payable(_dev);
        DevFee = _devFee;
    }

    function setHUB(address _hub) external onlyOwner {
        HUB = IHUB(_hub);
    }

    function setMustHold(bool _flag) external onlyOwner {
        mustHold = _flag;
    }

    function updateSweepersTreasury(address _treasury) external onlyOwner {
        sweepersTreasury = _treasury;
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint16 _minBidIncrementPercentage) external onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    function createAuction(address _nftContract, uint16 _tokenId, uint32 _startTime, uint32 _endTime, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        uint32 id = currentAuctionId++;

        auctionId[id] = Auction({
            contractAddress : INFT(_nftContract),
            tokenId : _tokenId,
            startTime : _startTime,
            endTime : _endTime,
            startingPrice : _startingPrice,
            currentBid : 0,
            previousBid : 0,
            activeBidId : 0,
            bidder : address(0),
            numberBids : 0,
            blind : false,
            settled : false,
            failed : false,
            hiddenImage : 'null'
        });
        activeAuctionCount++;

        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit AuctionCreated(id, _startTime, _endTime, _nftContract, _tokenId, false);
    }

    function createManyAuctionSameProject(address _nftContract, uint16[] calldata _tokenIds, uint32 _startTime, uint32 _endTime, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint32 id = currentAuctionId++;
            auctionId[id] = Auction({
                contractAddress : INFT(_nftContract),
                tokenId : _tokenIds[i],
                startTime : _startTime,
                endTime : _endTime,
                startingPrice : _startingPrice,
                currentBid : 0,
                previousBid : 0,
                activeBidId : 0,
                bidder : address(0),
                numberBids : 0,
                blind : false,
                settled : false,
                failed : false,
                hiddenImage : 'null'
            });
            activeAuctionCount++;

            IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            emit AuctionCreated(id, _startTime, _endTime, _nftContract, _tokenIds[i], false);
        }
    }

    function createBlindAuction(address _nftContract, uint32 _startTime, uint32 _endTime, string calldata _hiddenImage, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        uint32 id = currentAuctionId++;

        auctionId[id] = Auction({
            contractAddress : INFT(_nftContract),
            tokenId : 0,
            startTime : _startTime,
            endTime : _endTime,
            startingPrice : _startingPrice,
            currentBid : 0,
            previousBid : 0,
            activeBidId : 0,
            bidder : address(0),
            numberBids : 0,
            blind : true,
            settled : false,
            failed : false,
            hiddenImage : _hiddenImage
        });
        activeAuctionCount++;       

        emit AuctionCreated(id, _startTime, _endTime, _nftContract, 0, true);
    }

    function createManyBlindAuctionSameProject(address _nftContract, uint16 _numAuctions, uint32 _startTime, uint32 _endTime, string calldata _hiddenImage, uint256 _startingPrice) external onlySweepersTreasury nonReentrant {
        
        for(uint i = 0; i < _numAuctions; i++) {
            uint32 id = currentAuctionId++;
            auctionId[id] = Auction({
                contractAddress : INFT(_nftContract),
                tokenId : 0,
                startTime : _startTime,
                endTime : _endTime,
                startingPrice : _startingPrice,
                currentBid : 0,
                previousBid : 0,
                activeBidId : 0,
                bidder : address(0),
                numberBids : 0,
                blind : true,
                settled : false,
                failed : false,
                hiddenImage : _hiddenImage
            });
            activeAuctionCount++;

            emit AuctionCreated(id, _startTime, _endTime, _nftContract, 0, true);
        }
    }

    function updateBlindAuction(uint32 _id, uint16 _tokenId) external onlySweepersTreasury {
        require(auctionId[_id].tokenId == 0, "Auction already updated");
        auctionId[_id].tokenId = _tokenId;
        auctionId[_id].contractAddress.safeTransferFrom(msg.sender, address(this), _tokenId);
        auctionId[_id].blind = false;
    }

    function updateManyBlindAuction(uint32[] calldata _ids, uint16[] calldata _tokenIds) external onlySweepersTreasury {
        require(_ids.length == _tokenIds.length, "_id and tokenId must be same length");
        for(uint i = 0; i < _ids.length; i++) {
            require(auctionId[_ids[i]].tokenId == 0, "Auction already updated");
            auctionId[_ids[i]].tokenId = _tokenIds[i];
            auctionId[_ids[i]].contractAddress.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            auctionId[_ids[i]].blind = false;
        } 
    }

    function updateBlindImage(uint32 _id, string calldata _hiddenImage) external onlySweepersTreasury {
        auctionId[_id].hiddenImage = _hiddenImage;
    }

    function updateManyBlindImage(uint32[] calldata _ids, string calldata _hiddenImage) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            auctionId[_ids[i]].hiddenImage = _hiddenImage;
        } 
    }

    function updateAuctionStartingPrice(uint32 _id, uint256 _startingPrice) external onlySweepersTreasury {
        require(auctionId[_id].currentBid < auctionId[_id].startingPrice, 'Auction already met startingPrice');
        auctionId[_id].startingPrice = _startingPrice;
    }

    function updateManyAuctionStartingPrice(uint32[] calldata _ids, uint256 _startingPrice) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            if(auctionId[_ids[i]].currentBid < auctionId[_ids[i]].startingPrice) {
                auctionId[_ids[i]].startingPrice = _startingPrice;
            } else {
                continue;
            }
        }
    }

    function updateAuctionEndTime(uint32 _id, uint32 _newEndTime) external onlySweepersTreasury {
        require(auctionId[_id].currentBid == 0, 'Auction already met startingPrice');
        auctionId[_id].endTime = _newEndTime;
        emit AuctionExtended(_id, _newEndTime);
    }

    function updateManyAuctionEndTime(uint32[] calldata _ids, uint32 _newEndTime) external onlySweepersTreasury {
        for(uint i = 0; i < _ids.length; i++) {
            if(auctionId[_ids[i]].currentBid == 0) {
                auctionId[_ids[i]].endTime = _newEndTime;
                emit AuctionExtended(_ids[i], _newEndTime);
            } else {
                continue;
            }
        }
    }

    function emergencyCancelAllAuctions() external onlySweepersTreasury {
        for(uint32 i = 0; i < currentAuctionId; i++) {
            uint8 status = auctionStatus(i);
            if(status == 1) {
                _cancelAuction(i);
            } else {
                continue;
            }
        }
    }

    function emergencyCancelAuction(uint32 _id) external onlySweepersTreasury {
        require(auctionStatus(_id) == 1, 'Can only cancel active auctions');
        _cancelAuction(_id);
    }

    function _cancelAuction(uint32 _id) private {
        auctionId[_id].endTime = uint32(block.timestamp);
        auctionId[_id].failed = true;
        address lastBidder = auctionId[_id].bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            TOPIA.mint(lastBidder, auctionId[_id].currentBid);
            bidId[auctionId[_id].activeBidId].bidStatus = 3;
            auctionId[_id].previousBid = auctionId[_id].currentBid;
        }
        IERC721(auctionId[_id].contractAddress).transferFrom(address(this), Dev, auctionId[_id].tokenId);
        emit AuctionCanceled(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId);
    }

    /**
     * @notice Create a bid for a NFT, with a given amount.
     * @dev This contract only accepts payment in TOPIA.
     */
    function createBid(uint32 _id, uint256 _bidAmount) external payable holdsMetatopia nonReentrant {
        require(auctionStatus(_id) == 1, 'Auction is not Active');
        require(block.timestamp < auctionId[_id].endTime, 'Auction expired');
        require(msg.value == DevFee, 'Fee not covered');
        require(_bidAmount >= auctionId[_id].startingPrice, 'Bid amount must be at least starting price');
        require(
            _bidAmount >= auctionId[_id].currentBid + ((auctionId[_id].currentBid * minBidIncrementPercentage) / 10000),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address lastBidder = auctionId[_id].bidder;
        uint32 _bidId = currentBidId++;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            TOPIA.mint(lastBidder, auctionId[_id].currentBid);
            bidId[auctionId[_id].activeBidId].bidStatus = 2;
            auctionId[_id].previousBid = auctionId[_id].currentBid;
        }

        auctionId[_id].currentBid = _bidAmount;
        auctionId[_id].bidder = msg.sender;
        auctionId[_id].activeBidId = _bidId;
        auctionBids[_id].push(_bidId);
        auctionId[_id].numberBids++;
        bidId[_bidId].bidder = msg.sender;
        bidId[_bidId].bidAmount = _bidAmount;
        bidId[_bidId].auctionId = _id;
        bidId[_bidId].bidStatus = 1;
        userBids[msg.sender].push(_bidId);

        TOPIA.burnFrom(msg.sender, _bidAmount);

        // Extend the auction if the bid was received within `timeBufferThreshold` of the auction end time
        bool extended = auctionId[_id].endTime - block.timestamp < timeBufferThreshold;
        if (extended) {
            auctionId[_id].endTime = uint32(block.timestamp) + timeBuffer;
            emit AuctionExtended(_id, auctionId[_id].endTime);
        }

        Dev.transfer(DevFee);

        emit BidPlaced(_bidId, _id, msg.sender, _bidAmount);
    }

    /**
     * @notice Settle an auction, finalizing the bid and transferring the NFT to the winner.
     * @dev If there are no bids, the Auction is failed and can be relisted.
     */
    function _settleAuction(uint32 _id) external {
        require(auctionStatus(_id) == 2, "Auction can't be settled at this time");
        require(auctionId[_id].tokenId != 0, "Auction TokenId must be updated first");

        auctionId[_id].settled = true;
        if (auctionId[_id].bidder == address(0) && auctionId[_id].currentBid == 0) {
            auctionId[_id].failed = true;
            IERC721(auctionId[_id].contractAddress).transferFrom(address(this), Dev, auctionId[_id].tokenId);
            emit AuctionFailed(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId);
        } else {
            IERC721(auctionId[_id].contractAddress).transferFrom(address(this), auctionId[_id].bidder, auctionId[_id].tokenId);
        }
        activeAuctionCount--;
        emit AuctionSettled(_id, address(auctionId[_id].contractAddress), auctionId[_id].tokenId, auctionId[_id].bidder, auctionId[_id].currentBid);
    }

    function auctionStatus(uint32 _id) public view returns (uint8) {
        if (block.timestamp >= auctionId[_id].endTime && auctionId[_id].tokenId == 0) {
        return 5; // AWAITING TOKENID - Auction finished
        }
        if (auctionId[_id].failed) {
        return 4; // FAILED - not sold by end time
        }
        if (auctionId[_id].settled) {
        return 3; // SUCCESS - Bidder won 
        }
        if (block.timestamp >= auctionId[_id].endTime) {
        return 2; // AWAITING SETTLEMENT - Auction finished
        }
        if (block.timestamp <= auctionId[_id].endTime && block.timestamp >= auctionId[_id].startTime) {
        return 1; // ACTIVE - bids enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getBidsByAuctionId(uint32 _id) external view returns (uint32[] memory bidIds) {
        uint256 length = auctionBids[_id].length;
        bidIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            bidIds[i] = auctionBids[_id][i];
        }
    }

    function getBidsByUser(address _user) external view returns (uint32[] memory bidIds) {
        uint256 length = userBids[_user].length;
        bidIds = new uint32[](length);
        for(uint i = 0; i < length; i++) {
            bidIds[i] = userBids[_user][i];
        }
    }

    function getTotalBidsLength() external view returns (uint32) {
        return currentBidId - 1;
    }

    function getBidsLengthForAuction(uint32 _id) external view returns (uint256) {
        return auctionBids[_id].length;
    }

    function getBidsLengthForUser(address _user) external view returns (uint256) {
        return userBids[_user].length;
    }

    function getBidInfoByIndex(uint32 _bidId) external view returns (address _bidder, uint256 _bidAmount, uint32 _auctionId, string memory _bidStatus) {
        _bidder = bidId[_bidId].bidder;
        _bidAmount = bidId[_bidId].bidAmount;
        _auctionId = bidId[_bidId].auctionId;
        if(bidId[_bidId].bidStatus == 1) {
            _bidStatus = 'active';
        } else if(bidId[_bidId].bidStatus == 2) {
            _bidStatus = 'outbid';
        } else if(bidId[_bidId].bidStatus == 3) {
            _bidStatus = 'canceled';
        } else if(bidId[_bidId].bidStatus == 4) {
            _bidStatus = 'accepted';
        } else {
            _bidStatus = 'invalid BidID';
        }
    }

    function getBidStatus(uint32 _bidId) external view returns (string memory _bidStatus) {
        if(bidId[_bidId].bidStatus == 1) {
            _bidStatus = 'active';
        } else if(bidId[_bidId].bidStatus == 2) {
            _bidStatus = 'outbid';
        } else if(bidId[_bidId].bidStatus == 3) {
            _bidStatus = 'canceled';
        } else if(bidId[_bidId].bidStatus == 4) {
            _bidStatus = 'accepted';
        } else {
            _bidStatus = 'invalid BidID';
        }
    }

    function getActiveAuctions() external view returns (uint32[] memory _activeAuctions) {
        _activeAuctions = new uint32[](activeAuctionCount);
        for(uint32 i = 0; i < currentAuctionId; i++) {
            uint32 z = 0;
            uint8 status = auctionStatus(i);
            if(status == 1) {
                _activeAuctions[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    function getAllAuctions() external view returns (uint32[] memory auctions, uint8[] memory status) {
        auctions = new uint32[](currentAuctionId);
        status = new uint8[](currentAuctionId);
        for(uint32 i = 1; i <= currentAuctionId; i++) {
            auctions[i] = i;
            status[i] = auctionStatus(i);
        }
    }
}