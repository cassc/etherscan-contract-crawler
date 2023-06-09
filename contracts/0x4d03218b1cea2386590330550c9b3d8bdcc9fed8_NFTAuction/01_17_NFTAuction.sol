//     /\
//    /  \
//   |    |
//   |BITS|
//   |    |
//   |    |
//   |    |
//  '      `
//  |      |
//  |      |
//  |______|
//   '-`'-`   .
//   / . \'\ . .'
//  ''( .'\.' ' .;'
// '.;.;' ;'.;' ..;;'
/*
 * Audited by Kurama Audits for security and integrity.
 * Audit UUID: 3e0a6a0f-1e95-4e12-a39f-7d4e4f4c7f0a
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTFactory.sol";

contract NFTAuction is ReentrancyGuard, Ownable {
    // State Variables //
    address public constant ADMIN_WALLET = 0x9f643feCd9ebeAD21205b500FD91BB6ddF7dfCAe;
    uint256 public constant MIN_BID_PRICE = 0.16 ether;

    uint256 public startTime;
    uint256 public endTime;

    bool public refundEnabled = false;

    mapping(address => uint256) public userBids;
    mapping(address => bool) public userRefunds;
    mapping(address => bool) public userClaims;
    mapping(address => uint) public userPositions;

    NFTFactory public nftFactory;

    // Events //
    event BidPlaced(address user, uint256 bid);
    event NFTClaimed(address user, uint256 id);
    event RefundClaimed(address user, uint256 amount);
    event AdminPayment(uint256 amount);

    // Errors //
    error AuctionHasNotStartedYet();
    error AuctionHasEnded();
    error BidMustBeGreaterThan(uint256 amountRequired);
    error AuctionIsStillOngoing();
    error UserHasNotPlacedAnyBid();
    error NFTAlreadyClaimed();
    error UserIsNotAWinner();
    error RefundAlreadyClaimed();
    error UserIsAWinner();
    error AlreadyPayment();
    error RefundIsNotEnabled();

    constructor(address nftAddress, uint256 newStartTime) {
        nftFactory = NFTFactory(nftAddress);
        startTime = newStartTime;
        endTime = startTime + 7 days;
    }

    // External functions //
    function placeBid() external payable nonReentrant {
        if (block.timestamp < startTime)
            revert AuctionHasNotStartedYet();

        if (block.timestamp > endTime)
            revert AuctionHasEnded();

        if (msg.value == 0)
            revert BidMustBeGreaterThan(0);

        if ((userBids[msg.sender] + msg.value) < MIN_BID_PRICE)
            revert BidMustBeGreaterThan(MIN_BID_PRICE);

        userBids[msg.sender] += msg.value;

        emit BidPlaced(msg.sender, msg.value);
    }

    function claimNFT() external nonReentrant {
        if (block.timestamp < endTime)
            revert AuctionIsStillOngoing();

        if (userBids[msg.sender] == 0)
            revert UserHasNotPlacedAnyBid();

        if (userClaims[msg.sender])
            revert NFTAlreadyClaimed();

        uint position = userPositions[msg.sender];

        if (position == 0)
            revert UserIsNotAWinner();

        userClaims[msg.sender] = true;
        nftFactory.mint(msg.sender, position);

        emit NFTClaimed(msg.sender, position);
    }

    function claimRefund() external nonReentrant {
        if (block.timestamp < endTime)
            revert AuctionIsStillOngoing();
        
        if (!refundEnabled)
            revert RefundIsNotEnabled();

        if (userBids[msg.sender] == 0)
            revert UserHasNotPlacedAnyBid();

        if (userRefunds[msg.sender])
            revert RefundAlreadyClaimed();

        uint position = userPositions[msg.sender];

        if (position > 0)
            revert UserIsAWinner();

        userRefunds[msg.sender] = true;
        payable(msg.sender).transfer(userBids[msg.sender]);

        emit RefundClaimed(msg.sender, userBids[msg.sender]);
    }

    function setPositions(address[] memory positions, uint base, bool _refundEnabled) external onlyOwner {
        if (block.timestamp < endTime)
            revert AuctionIsStillOngoing();

        for (uint i = 0; i < positions.length; i++) {
            userPositions[positions[i]] = base + i;
        }
        refundEnabled = _refundEnabled;
    }

    function payAuction(uint256 amount) external onlyOwner {
        if (block.timestamp < endTime)
            revert AuctionIsStillOngoing();

        payable(ADMIN_WALLET).transfer(amount);

        emit AdminPayment(amount);
    }
}