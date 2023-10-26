// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*//////////////////////////////////////////////////////////////////////////
                             ERRORS
//////////////////////////////////////////////////////////////////////////*/
library Errors {
    error NotSeeder();
    error AddressClaimedAlready(address claimer);
    error DistributionNotStarted(uint256 currentTs, uint256 kickOffTs);
    error InvalidAuraDelegateManager();
    error InvalidOwnerAddress();
    error InvalidRewardToken();
    error InvalidStakeAmount();
    error InvalidWithdrawAmount();
    error PoolLengthExceeded();
    error ProofNotValid();
    error RewardTooHigh();
    error TokenTransferFailure();
    error Unauthorized();
    error StaleChainlinkFeed(uint256 currentTimestamp, uint256 lastTimeUpdated);
}