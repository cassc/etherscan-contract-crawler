// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MerkleDistributor} from "./MerkleDistributor.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error EndTimeInPast();
error ClaimWindowFinished();
error NoWithdrawDuringClaim();

// Copied from https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributorWithDeadline.sol
contract MerkleDistributorWithDeadline is MerkleDistributor {
    using SafeERC20 for IERC20;

    uint256 public immutable endTime;
    address public immutable nonClaimedTokensReceiver;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 endTime_,
        address nonClaimedTokensReceiver_
    ) MerkleDistributor(token_, merkleRoot_) {
        if (endTime_ <= block.timestamp) revert EndTimeInPast();
        endTime = endTime_;
        nonClaimedTokensReceiver = nonClaimedTokensReceiver_;
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public virtual override {
        if (block.timestamp > endTime) revert ClaimWindowFinished();
        super.claim(index, account, amount, merkleProof);
    }

    function withdraw() external {
        if (block.timestamp < endTime) revert NoWithdrawDuringClaim();
        IERC20(token).safeTransfer(
            nonClaimedTokensReceiver,
            IERC20(token).balanceOf(address(this))
        );
    }
}