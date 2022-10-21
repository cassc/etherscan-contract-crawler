// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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

contract CharlesDBAuction is Ownable {
    using SafeMath for uint256;

    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;

    address payable public seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    uint32 public timerAuction;
    uint public tax;

    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid,
        uint32 _timerAuction,
        uint _tax
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = _startingBid; 
        timerAuction = _timerAuction;
        tax = _tax; 
    }

    function start() external onlyOwner {
        require(!started, "started");
        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = uint32(block.timestamp + timerAuction);

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(!ended, "auction ended");
        require(block.timestamp < endAt, "ended");

        uint checkHighestBid = bids[msg.sender];
        uint userBid = msg.value.sub(tax);

        require(userBid+checkHighestBid > highestBid, "Value is lower than Highest");

        bids[msg.sender] += userBid;
        highestBidder = msg.sender;
        highestBid = userBid+checkHighestBid;

        emit Bid(msg.sender, userBid+checkHighestBid);
    }

    function withdraw() external {
        require(bids[msg.sender] != 0, "not bidder");
        require(bids[msg.sender] != highestBid, "highest bidder");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: bal} ("");
        require(success, "Transfer failed.");

        emit Withdraw(msg.sender, bal);
    }

    function end() external onlyOwner {
        require(started, "not started");
        require(!ended, "ended");
        
        ended = true;
        
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }

    function withdrawOwner(uint _bal) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _bal} ("");
        require(success, "Transfer failed.");
    }

    function balanceUser() public view returns (uint){
        return bids[msg.sender];
    }
}