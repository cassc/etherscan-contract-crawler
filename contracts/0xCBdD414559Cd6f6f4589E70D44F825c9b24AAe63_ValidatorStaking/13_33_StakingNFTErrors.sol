// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library StakingNFTErrors {
    error CallerNotTokenOwner(address caller);
    error LockDurationGreaterThanGovernanceLock();
    error LockDurationGreaterThanMintLock();
    error LockDurationWithdrawTimeNotReached();
    error InvalidTokenId(uint256 tokenId);
    error MintAmountExceedsMaximumSupply();
    error FreeAfterTimeNotReached();
    error BalanceLessThanReserve(uint256 balance, uint256 reserve);
    error SlushTooLarge(uint256 slush);
    error MintAmountZero();
}