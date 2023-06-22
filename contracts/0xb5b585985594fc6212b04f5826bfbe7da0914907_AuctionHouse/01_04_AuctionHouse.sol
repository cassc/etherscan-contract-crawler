// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface INFTContract {
    function publicMint(address to, uint256 auctionID) external;

    function totalSupply() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);
}

contract AuctionHouse is Ownable {
    using SafeMath for uint256;
    event BidEvent(uint256 auctionId, address from, uint256 amount);

    struct Auction {
        uint256 startAt;
        uint256 duration;
        bool active;
        mapping(address => uint256) bids;
        address highestBidder;
        uint256 highestBid;
        bool auctionCreated;
        uint256 tokenMinted;
    }

    struct Bid {
        address from;
        uint256 amount;
    }

    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => Bid[]) private bids;
    mapping(address => bool) private AdminWhitelist;

    uint256 private currentAuctionId = 1;
    uint256 public minAuctionLength = 100;
    uint256 public minBidIncrement = 0.01 ether;
    uint256 public Generated = 0;

    INFTContract NFTContract;
    address public ownerAddress;

    modifier onlyAdmin() {
        require(
            AdminWhitelist[msg.sender] || msg.sender == owner(),
            "You do not have admin access"
        );
        _;
    }

    constructor(address contractAddress, address _owner) {
        NFTContract = INFTContract(contractAddress);
        ownerAddress = _owner;
    }

    function createAuction(
        uint256 duration
    ) external onlyAdmin returns (uint256) {
        // require(duration > 0, "Duration should be greater than zero");
        require(
            duration >= minAuctionLength,
            "Duration should be greater than minAuctionLength"
        );

        require(canCreateAuction(), "Can not create auction");

        auctions[currentAuctionId].startAt = block.timestamp;
        auctions[currentAuctionId].duration = duration;
        auctions[currentAuctionId].active = true;
        auctions[currentAuctionId].auctionCreated = true;
        currentAuctionId++;
        return currentAuctionId - 1;
    }

    function mintOwner() public onlyAdmin {
        require(canCreateAuction(), "Can not create auction");

        auctions[currentAuctionId].startAt = block.timestamp;
        auctions[currentAuctionId].duration = 0;
        auctions[currentAuctionId].active = false;
        auctions[currentAuctionId].auctionCreated = true;

        NFTContract.publicMint(msg.sender, currentAuctionId);
        auctions[currentAuctionId].tokenMinted = NFTContract.totalSupply();
        currentAuctionId++;
    }

    function bid(uint256 auctionId) public payable {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction does not exist or has ended");
        require(msg.value > 0, "Missing amount");
        require(
            block.timestamp < auction.startAt + auction.duration,
            "Auction has ended"
        );

        uint256 currentBid = msg.value;
        require(
            currentBid > auction.highestBid,
            "Amount must be higher than highest bid"
        );

        require(
            currentBid.sub(auction.highestBid) >= minBidIncrement,
            "Bid increment is too low"
        );

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = currentBid;
        auction.bids[msg.sender] = currentBid;

        Bid memory newBid = Bid(msg.sender, msg.value);
        bids[auctionId].push(newBid);

        emit BidEvent(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) public {
        Auction storage auction = auctions[auctionId];
        require(auction.auctionCreated, "Auction does not exist");
        require(
            block.timestamp >= auction.startAt + auction.duration,
            "Auction has not ended yet"
        );
        require(auction.active, "Auction must be active");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            NFTContract.publicMint(auction.highestBidder, auctionId);
            //get the token id minted
            auction.tokenMinted = NFTContract.totalSupply();
            payable(ownerAddress).transfer(auction.highestBid);
            Generated = Generated + auction.highestBid;
        } else {
            NFTContract.publicMint(owner(), auctionId);
        }
    }

    function setMinAuctionLength(uint256 _minAuctionLength) public onlyAdmin {
        minAuctionLength = _minAuctionLength;
    }

    function setMinBidIncrement(uint256 _minBidIncrement) public onlyAdmin {
        minBidIncrement = _minBidIncrement;
    }

    function getAuctionInfo(
        uint256 auctionId
    )
        public
        view
        returns (
            uint256 startAt,
            uint256 duration,
            bool active,
            address highestBidder,
            uint256 highestBid,
            bool auctionCreated
        )
    {
        Auction storage auction = auctions[auctionId];
        startAt = auction.startAt;
        duration = auction.duration;
        active = auction.active;
        highestBidder = auction.highestBidder;
        highestBid = auction.highestBid;
        auctionCreated = auction.auctionCreated;

        return (
            startAt,
            duration,
            active,
            highestBidder,
            highestBid,
            auctionCreated
        );
    }

    function getBidsForAuction(
        uint256 auctionId
    ) public view returns (Bid[] memory) {
        return bids[auctionId];
    }

    function getTotalBidsForAuction(
        uint256 auctionId
    ) public view returns (uint256) {
        return bids[auctionId].length;
    }

    function getCurrentAuctionId() public view returns (uint256) {
        return currentAuctionId - 1;
    }

    function getTimeLeftCurrentAuction() public view returns (uint256) {
        uint256 auctionId = getCurrentAuctionId();
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction does not exist or has ended");
        require(
            block.timestamp < auction.startAt + auction.duration,
            "Auction has ended"
        );
        return auction.startAt + auction.duration - block.timestamp;
    }

    function getTimeLeftAuctionByID(
        uint256 auctionId
    ) public view returns (uint256) {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction does not exist or has ended");
        require(
            block.timestamp < auction.startAt + auction.duration,
            "Auction has ended"
        );
        return auction.startAt + auction.duration - block.timestamp;
    }

    function canCreateAuction() public view returns (bool) {
        if (NFTContract.totalSupply() < NFTContract.MAX_SUPPLY()) {
            return true;
        } else {
            return false;
        }
    }

    function whitelistAdmin(address _address) public onlyOwner {
        AdminWhitelist[_address] = true;
    }

    function removeAdminWhitelist(address _address) public onlyOwner {
        AdminWhitelist[_address] = false;
    }

    function setOwner(address _owner) public onlyOwner {
        ownerAddress = _owner;
    }

    function withdraw() external payable onlyOwner {
        require(
            auctions[getCurrentAuctionId()].active == false,
            "Cannot withdraw while there is an active auction"
        );

        (bool payment, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(payment);
    }
}