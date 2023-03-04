// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/ItemRef.sol';

/// @dev the fee rewards distributer interface
interface ITradingPairFeeDistributer {
    /// @dev the lock event
    event OnLock(address indexed account, uint256 amount);

    /// @dev the unlock event
    event OnUnlock(address indexed account, uint256 amount);

    /// @dev the claim event
    event OnClaim(address indexed account, uint256 asset1Count, uint256 asset2Count);

    /// @dev locks the certain ammount of tokens
    function lockFeeTokens(uint256 amount) external;

    /// @dev unlocks certain ammount of tokens
    function unlockFeeTokens(uint256 amount) external;

    /// @dev the total number of fee tokens locked
    function totalFeeTokensLocked() external view returns (uint256);

    /// @dev tokens locked at the beginning of the current round
    function currentRoundBeginingTotalFeeTokensLocked()
        external
        view
        returns (uint256);

    /// @dev the asset1 to distrubute at current fee round
    function asset1ToDistributeCurrentRound() external view returns (uint256);

    /// @dev the asset2 to distrubute at current fee round
    function asset2ToDistributeCurrentRound() external view returns (uint256);

    /// @dev the assets to distrubute at current fee round
    function assetsToDistributeCurrentRound()
        external
        view
        returns (uint256, uint256);

    /// @dev the asset1 total distributed counts for statistics
    function asset1DistributedTotal() external view returns (uint256);

    /// @dev the asset1 total distributed counts for statistics
    function asset2DistributedTotal() external view returns (uint256);

    /// @dev the assets total distributed counts for statistics
    function assetsDistributedTotal() external view returns (uint256, uint256);

    /// @dev returns the number of the last round in which the account received a reward
    function getClaimRound(address account) external view returns (uint256);

    /// @dev returns the account ammount of tokens lock
    function getLock(address account) external view returns (uint256);

    /// @dev returns current time rewards counts for speciffic account
    function getExpectedRewardForAccount(address account)
        external
        view
        returns (uint256, uint256);

    /// @dev current reward for account current stack
    /// this value may be decrease (if claimed rewards or added stacks) or increase (if fee arrives)
    function getExpectedRewardForAccountNextRound(address account)
        external
        view
        returns (uint256, uint256);

    /// @dev reward for tokens count
    function getExpectedRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);

    /// @dev current reward for tokens count on next round
    /// this value may be decrease (if claimed rewards or added stacks) or increase (if fee arrives)
    function getExpectedRewardForTokensCountNextRound(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);

    /// @dev grants rewards to sender
    function claimRewards() external;

    /// @dev returns the time between the fee rounds
    function feeRoundInterval() external view returns (uint256);

    /// @dev retruns the current fee round number
    function feeRoundNumber() external view returns (uint256);

    /// @dev remaining minutes until the next fee round
    function nextFeeRoundLapsedMinutes() external view returns (uint256);

    /// @dev remaining time until next fee round
    function nextFeeRoundLapsedTime() external view returns (uint256);

    /// @dev the time when available transfer the system to next fee round
    /// this transfer happens automatically when call any write function
    function nextFeeRoundTime() external view returns (uint256);

    /// @dev transfers the system into next fee round.
    /// this is technical function, available for everyone.
    /// despite this happens automatically when call any write function, sometimes it can be useful to scroll the state manually
    function tryNextFeeRound() external;

    /// @dev returns the fee asset reference
    function asset(uint256 assetCode) external view returns (ItemRef memory);

    /// @dev returns the fee asset count
    function assetCount(uint256 assetCode) external view returns (uint256);

    /// @dev returns the all fee assets counts
    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count);

    /// @dev the trading pair algorithm contract
    function tradingPair() external view returns (address);

    /// @dev the position id
    function positionId() external view returns (uint256);
}