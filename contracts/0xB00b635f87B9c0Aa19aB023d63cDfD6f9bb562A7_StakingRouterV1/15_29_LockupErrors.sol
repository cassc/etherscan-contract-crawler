// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library LockupErrors {
    error AddressNotAllowedToSendEther();
    error OnlyStakingNFTAllowed();
    error ContractDoesNotOwnTokenID(uint256 tokenID_);
    error AddressAlreadyLockedUp();
    error TokenIDAlreadyClaimed(uint256 tokenID_);
    error InsufficientBalanceForEarlyExit(uint256 exitValue, uint256 currentBalance);
    error UserHasNoPosition();
    error PreLockStateRequired();
    error PreLockStateNotAllowed();
    error PostLockStateNotAllowed();
    error PostLockStateRequired();
    error PayoutUnsafe();
    error PayoutSafe();
    error TokenIDNotLocked(uint256 tokenID_);
    error InvalidPositionWithdrawPeriod(uint256 withdrawFreeAfter, uint256 endBlock);
    error InLockStateRequired();

    error BonusTokenNotCreated();
    error BonusTokenAlreadyCreated();
    error NotEnoughALCAToStake(uint256 currentBalance, uint256 expectedAmount);

    error InvalidTotalSharesValue();
}