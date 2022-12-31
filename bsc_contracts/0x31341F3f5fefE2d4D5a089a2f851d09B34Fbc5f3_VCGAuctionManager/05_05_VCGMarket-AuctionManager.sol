// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IAuctionManager.sol";

contract VCGAuctionManager is IAuctionManager, Ownable {
    using SafeMath for uint256;

    address marketplace;

    constructor(address _marketplace) {
        setupMarketplace(_marketplace);
    }

    modifier onlyMarketPlace() {
        require(msg.sender == marketplace);
        _;
    }

    mapping(uint256 => address) highestBidder; // offer nonce => bidder address
    mapping(uint256 => uint256) highestBid; // offer nonce => bid amount
    mapping(uint256 => mapping(address => uint256)) bids; // offer nonce => bidder => bid amount

    function bid(
        uint256 nonce,
        uint256 amount,
        address bidder
    ) external onlyMarketPlace {
        require(
            amount > highestBid[nonce],
            "AuctionManager: bid is lesser than highest bid"
        );

        bids[nonce][highestBidder[nonce]] += highestBid[nonce];

        highestBidder[nonce] = bidder;
        highestBid[nonce] = amount;
    }

    function getHighestBidder(uint256 nonce)
        external
        view
        returns (address, uint256)
    {
        return (highestBidder[nonce], highestBid[nonce]);
    }

    function getWithdrawAmount(uint256 nonce, address bidder)
        external
        onlyMarketPlace
        returns (uint256)
    {
        require(
            bids[nonce][bidder] > 0,
            "AuctionManager: not bidder/ already claim"
        );
        uint256 withdrawAmount = bids[nonce][bidder];
        bids[nonce][bidder] = 0;
        return withdrawAmount;
    }

    function setupMarketplace(address _marketplace) public onlyOwner {
        marketplace = _marketplace;
    }
}