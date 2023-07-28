// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {Address} from "@openzeppelin/utils/Address.sol";

error NoCommitmentRegistered();
error PleaseSendETH();
error AuctionNotSuccessful();
error AuctionHasFinalized();
error AuctionHasNotFinalized();
error ClaimTokensInstead();

contract BootstrappingAuction {
    using Address for address payable;

    event FinalizedAuction(uint256 timestamp);
    event ClaimedPRTC(address indexed who, uint256 amount);
    event CommittedETH(address indexed who, uint256 amount);
    event RefundETH(address indexed who, uint256 amount);

    uint256 private constant PRICE_PER_PRTC = 52_137_600_000_000 wei;
    uint256 private constant TOTAL_TOKENS = 10_000_000e18;

    IERC20 private immutable prtc;
    address private immutable beneficiary;

    uint256 private immutable startTime;
    uint256 private immutable endTime;

    uint256 public totalCommitments;
    bool public isAuctionFinalized;

    mapping(address user => uint256 amountCommitted) public commitments;

    constructor(IERC20 _prtc, address _beneficiary) {
        prtc = _prtc;
        beneficiary = _beneficiary;
        startTime = block.timestamp;
        endTime = block.timestamp + 1 days + 5 hours;
    }

    function commitETH() external payable {
        if (isAuctionFinalized || auctionSuccessful()) revert AuctionHasFinalized();
        if (msg.value == 0) revert PleaseSendETH();

        commitments[msg.sender] += msg.value;
        totalCommitments += msg.value;

        emit CommittedETH(msg.sender, msg.value);
    }

    function claimTokens() external {
        if (!auctionSuccessful()) revert AuctionNotSuccessful();
        if (commitments[msg.sender] == 0) revert NoCommitmentRegistered();

        uint256 correspondingAmount = commitments[msg.sender] * TOTAL_TOKENS / totalCommitments;

        delete commitments[msg.sender];

        prtc.transfer(msg.sender, correspondingAmount);

        emit ClaimedPRTC(msg.sender, correspondingAmount);
    }

    function claimETH() external {
        if (!isAuctionFinalized) revert AuctionHasNotFinalized();
        if (commitments[msg.sender] == 0) revert NoCommitmentRegistered();
        if (auctionSuccessful()) revert ClaimTokensInstead();

        uint256 amount = commitments[msg.sender];

        delete commitments[msg.sender];

        payable(msg.sender).sendValue(amount);

        emit RefundETH(msg.sender, amount);
    }

    function finalizeAuction() external {
        if (isAuctionFinalized) revert AuctionHasFinalized();
        if (!(block.timestamp >= endTime || auctionSuccessful())) {
            revert AuctionHasNotFinalized();
        }

        isAuctionFinalized = true;

        if (auctionSuccessful()) {
            payable(beneficiary).sendValue(address(this).balance);
        } else {
            prtc.transfer(beneficiary, TOTAL_TOKENS);
        }

        emit FinalizedAuction(block.timestamp);
    }

    function auctionSuccessful() public view returns (bool) {
        return totalCommitments >= (PRICE_PER_PRTC * TOTAL_TOKENS / 1 ether);
    }
}