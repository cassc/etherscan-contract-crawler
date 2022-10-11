// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "hardhat/console.sol";


contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 amount);

    ERC721A public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    constructor(
        address _nft,
        uint256 _nftId,
        uint256 _startingBid
    ) {
        nft = ERC721A(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    /// @dev seller needs to approve contract beforehand to allow it to transfer the nft on his behalf
    function start(uint32 _duration) external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");
        started = true;
        endAt = uint32(block.timestamp + _duration);
        //nft.transferFrom(msg.sender, address(this), nftId);
        // useless to transfer twice, just transfer at settlement

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");

        highestBid = msg.value;
        highestBidder = msg.sender;
        //we need to set highestBidder before highestBid
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        //prevent highest bidder to default on his bid after auction is ended
        
        require(highestBidder != msg.sender, "highestBidder cant withdraw");
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(msg.sender == seller, "not seller");
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended");

        ended = true;

        if (highestBidder != address(0)) {
            nft.transferFrom(seller, highestBidder, nftId); //transfer from seller instead
            seller.transfer(highestBid);
        }

        emit End(highestBidder, highestBid);
    }
}