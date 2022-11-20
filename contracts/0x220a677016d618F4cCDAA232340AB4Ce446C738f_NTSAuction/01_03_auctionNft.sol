// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract NTSAuction is Ownable{

    event Start();
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, BidStr highestBid);
    event Bid(address indexed sender, BidStr highestBid);
    
    address private cath = 0x56bDc5fE7f9752E7F5a381E394acFE72A724462b;

    //define our bidding structure
    struct BidStr {
            uint BidValue;
            string imageId;
            string name;
        }
    
    struct historicalBid {
        string name;
        address bidder;
    }

    mapping(string => historicalBid) public bidStorage;

    BidStr public highestBid;

    uint public minIncrement = 100000000000000000; //0.1 eth in wei
    uint bidTimeExtension = 15 minutes;

    address public highestBidder;

    uint public endAt;
    bool public started;
    bool public ended;
    
    mapping(address => uint) public bids;
    address[] public bidders;

    constructor() {
        highestBid = BidStr(0, '', '');
    }


    function start() external onlyOwner {
        require(!started, "started");
        started = true;
        endAt = block.timestamp + 3 days;
        emit Start();
    }

    function bid(
                string memory _imageID,
                string memory _imageName) external payable {
        require(started, "Auction not started yet");
        require(block.timestamp < endAt, "Auction is already over");
        require(msg.value >= highestBid.BidValue + minIncrement, "You must bid at least 0.1 eth higher than the previous bid");
        require(msg.sender != highestBidder, "You are already the highest bidder");

        address previousHighestBidder = highestBidder;

        bidStorage[_imageID] = historicalBid(_imageName, msg.sender);

        highestBidder = msg.sender;
        highestBid = BidStr(msg.value, _imageID, _imageName);
        bids[highestBidder] += highestBid.BidValue;
        
        //send money back to previously highest bidder
        payable(previousHighestBidder).transfer(bids[previousHighestBidder]);
        bids[previousHighestBidder] = 0;

        // Allow 15 minutes for next bid if auction is almost done.
        if(endAt - block.timestamp < bidTimeExtension) {
            endAt = block.timestamp + bidTimeExtension;
        }
        
        emit Bid(msg.sender, highestBid);
    }

    function gethighestBid() public view returns (BidStr memory) {
        return highestBid;
    }

    function getHighestBidder() public view returns (address) {
        return highestBidder;
    }

    function end() public {
        require(endAt <= block.timestamp, "Auction is not over yet!");
        require(!ended, "End already called");

        payable(cath).transfer((highestBid.BidValue * 9) / 10);
        payable(owner()).transfer((highestBid.BidValue  / 10));

        bids[highestBidder] = 0;

        ended = true;
    }
}