// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Auction
 * @notice BlindAuction contract, inspired by Heedong, Kubz and Captainz contracts.
 * All credits to them for the ideas and most of the code.
 * See 0x52A494dbf47107Cc0c624EE10703abecAF586776 proxy to 0x5d7b782ec34cae8b38a56c1a3487337583178466
 */
contract Auction is ReentrancyGuard, Ownable {
    enum AuctionState {
        NOT_STARTED,
        BIDDING_STARTED,
        BIDDING_ENDED,
        REFUND_STARTED,
        REFUND_ENDED
    }
    AuctionState public auctionState;
    address public financeWalletAddress;
    bytes32 private merkleRootForWonItemsCount;

    uint256 public MAX_BID_AMOUNT = 15000000000000000000; // 15 Eth
    uint256 public MIN_BID_AMOUNT;
    uint256 public BID_ITEMS_COUNT;

    uint256 public finalPrice;
    uint256 public totalWonItemsCount;
    uint256 public withdrawn;

    address[] public bidders;

    struct Bid {
        bool exists;
        address bidder;
        uint256 amount;
        uint32 createdAt;
        uint32 updatedAt;
    }

    struct BidderRefundStatus {
        address bidder;
        bool isRefunded;
    }

    mapping(address => Bid) private userBid; // address => bid
    mapping(address => bool) public isUserRefunded; // address => user has refunded, whether as winner or loser

    //  ============================================================
    //  Modifiers
    //  ============================================================
    modifier auctionMustNotHaveStarted() {
        require(
            auctionState == AuctionState.NOT_STARTED,
            "Auction already started"
        );
        _;
    }

    //  ============================================================
    //  Events
    //  ============================================================
    event UserEnteredBid(
        address indexed user,
        uint256 bidAmount,
        bool indexed newUser
    );

    event UserRefunded(
        address indexed user,
        uint256 bidAmount,
        uint256 indexed wonItemsCount
    );

    //  ============================================================
    //  Init
    //  ============================================================

    constructor(address financeWallet, uint64 minBidAmount, uint256 bidItemsCount) {
        _setFinanceWalletAddress(financeWallet);
        MIN_BID_AMOUNT = minBidAmount;
        BID_ITEMS_COUNT = bidItemsCount;
    }

    receive() external payable {}

    fallback() external payable {}

    //  ============================================================
    //  Won Items Count Verification
    //  ============================================================
    /// @dev returns the merkle root for the won items count
    /// @return merkle root for the won items count
    function getMerkleRootForWonItemsCount()
    external
    view
    onlyOwner
    returns (bytes32)
    {
        return merkleRootForWonItemsCount;
    }

    /// @dev sets the merkle root for the won items count
    /// @param merkleRoot merkle root for the won items count
    function setMerkleRootForWonItemsCount(
        bytes32 merkleRoot
    ) external onlyOwner {
        merkleRootForWonItemsCount = merkleRoot;
    }

    /// @dev verifies the won items count
    /// @param _address user address
    /// @param proof merkle proof
    /// @param wonItemsCount won items count
    function verifyWonItemsCount(
        address _address,
        bytes32[] calldata proof,
        uint256 wonItemsCount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_address, wonItemsCount)))
        );
        return MerkleProof.verify(proof, merkleRootForWonItemsCount, leaf);
    }

    //  ============================================================
    //  Bid Management
    //  ============================================================
    /// @dev commits or increases the bid
    function commitBid() external payable {
        require(
            auctionState == AuctionState.BIDDING_STARTED,
            "Bidding is not open"
        );
        require(msg.value != 0, "Bid must be > 0");
        uint256 newAmount = userBid[msg.sender].amount + msg.value;
        require(newAmount >= MIN_BID_AMOUNT, "Min Bid Required");
        require(newAmount <= MAX_BID_AMOUNT, "Max Bid Exceeded");

        emit UserEnteredBid(
            msg.sender,
            newAmount,
            !userBid[msg.sender].exists
        );

        if (userBid[msg.sender].exists) {
            userBid[msg.sender].amount = newAmount;
            userBid[msg.sender].updatedAt = uint32(block.timestamp);
        } else {
            userBid[msg.sender] = Bid({
            exists: true,
            bidder: msg.sender,
            amount: newAmount,
            createdAt: uint32(block.timestamp),
            updatedAt: uint32(block.timestamp)
            });
            bidders.push(msg.sender);
        }
    }

    /// @dev returns a list of bidders and their bid amounts
    /// @return bids list of bids
    function getBids() external view returns (Bid[] memory bids) {
        Bid[] memory _bids = new Bid[](bidders.length);
        for (uint256 i; i < bidders.length; i++) {
            _bids[i] = userBid[bidders[i]];
        }
        return _bids;
    }

    /// @dev gets user's bid
    function getUserBid(address bidder) external view returns (uint256 bidAmount) {
        return userBid[bidder].amount;
    }

    /// @dev gets the number of biders
    function getBiddersLength() external view returns (uint256) {
        return bidders.length;
    }

    /// @dev gets a part of the bidders list
    /// @param fromIdx start index
    /// @param toIdx end index
    /// @return part of the bidders list
    function getBidders(
        uint256 fromIdx,
        uint256 toIdx
    ) external view returns (address[] memory) {
        toIdx = Math.min(toIdx, bidders.length);
        address[] memory part = new address[](toIdx - fromIdx);
        for (uint256 i; i < toIdx - fromIdx; i++) {
            part[i] = bidders[i + fromIdx];
        }
        return part;
    }

    /// @dev gets all the bidders
    /// @return bidders list of bidders
    function getBiddersAll() external view returns (address[] memory) {
        return bidders;
    }

    //  ============================================================
    //  Financial Management
    //  ============================================================
    /// @dev allows user to refund to their wallet
    /// @param proof merkle proof
    /// @param wonItemsCount user won items count
    function refund(
        bytes32[] calldata proof,
        uint256 wonItemsCount
    ) external nonReentrant {
        uint256 userBidAmount = userBid[msg.sender].amount;
        require(
            auctionState == AuctionState.REFUND_STARTED,
            "Refund not started yet"
        );
        require(finalPrice > 0, "Final price not set");
        require(verifyWonItemsCount(msg.sender, proof, wonItemsCount), "Invalid proof");
        require(userBidAmount > 0, "No bid record");
        require(!isUserRefunded[msg.sender], "Already refunded");

        uint256 refundAmount = userBidAmount - (finalPrice * wonItemsCount);
        require(refundAmount <= userBidAmount, "underflow");
        require(refundAmount > 0, "No refund needed");

        isUserRefunded[msg.sender] = true;
        emit UserRefunded(msg.sender, refundAmount, wonItemsCount);
        _withdraw(msg.sender, refundAmount);
    }

    /// @dev withdraws the sales to the finance wallet
    function withdrawSales() external onlyOwner {
        require(
            auctionState >= AuctionState.BIDDING_ENDED,
            "Auction not concluding"
        );
        require(totalWonItemsCount > 0, "totalWonItemsCount not set");
        require(finalPrice > 0, "finalPrice not set");
        uint256 sales = totalWonItemsCount * finalPrice;
        uint256 available = sales - withdrawn;
        require(available > 0, "No balance to withdraw");
        _withdraw(financeWalletAddress, available);
    }

    /// @dev withdraw all proceeds to the finance wallet
    function withdrawAll() external onlyOwner {
        require(
            auctionState >= AuctionState.REFUND_ENDED,
            "Auction refund not ended"
        );
        _withdraw(financeWalletAddress, address(this).balance);
    }

    /// @dev withdraws a fixed amount to the given address
    /// @param _address address to withdraw to
    /// @param _amount amount to withdraw
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
        withdrawn += _amount;
    }

    /// @dev sets the finance wallet address
    /// @param _financeWalletAddress finance wallet address
    function _setFinanceWalletAddress(
        address _financeWalletAddress
    ) private {
        require(_financeWalletAddress != address(0), "Invalid address");
        financeWalletAddress = _financeWalletAddress;
    }

    //  ============================================================
    //  Auction Administration
    //  ============================================================

    function setMinBidAmount(
        uint256 amount
    ) external onlyOwner {
        MIN_BID_AMOUNT = amount;
    }

    function setMaxBidAmount(
        uint256 amount
    ) external onlyOwner {
        MAX_BID_AMOUNT = amount;
    }

    function setBidItemsCount(
        uint256 count
    ) external auctionMustNotHaveStarted onlyOwner {
        BID_ITEMS_COUNT = count;
    }

    function setTotalWonItemsCount(uint256 items) external onlyOwner {
        require(items <= BID_ITEMS_COUNT, "Too many won items");
        totalWonItemsCount = items;
    }

    function setFinalPrice(uint256 price) external onlyOwner {
        require(price >= MIN_BID_AMOUNT, "Price too low");
        finalPrice = price;
    }

    function getFinalPrice() external view returns (uint256) {
        return finalPrice;
    }

    function setAuctionState(uint8 state) external onlyOwner {
        auctionState = AuctionState(state);
    }

    function getAuctionState() external view returns (uint8) {
        return uint8(auctionState);
    }

    function getIsUserRefunded(address user) external view returns (bool) {
        return isUserRefunded[user];
    }

    function getRefundStatus()
    external
    view
    returns (BidderRefundStatus[] memory)
    {
        BidderRefundStatus[] memory _status = new BidderRefundStatus[](bidders.length);
        for (uint256 i; i < bidders.length; i++) {
            _status[i] = BidderRefundStatus(bidders[i], isUserRefunded[bidders[i]]);
        }
        return _status;
    }
}