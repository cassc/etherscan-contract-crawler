// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/ItemRef.sol';

interface ITradingPairFeeDistributer {
    function lockFeeTokens(uint256 amount) external;

    function unlockFeeTokens(uint256 amount) external;

    function claimRewards() external;

    function nextFeeRoundLapsedMinutes() external view returns (uint256);

    function tryNextFeeRound() external;

    function asset(uint256 assetCode) external view returns (ItemRef memory);

    function assetCount(uint256 assetCode) external view returns (uint256);

    function allAssetsCounts()
        external
        view
        returns (uint256 asset1Count, uint256 asset2Count);

    /// @dev the trading pair algorithm contract
    function tradingPair() external view returns (address);

    /// @dev the position id
    function positionId() external view returns (uint256);

    /// @dev reward for tokens count
    function getRewardForTokensCount(uint256 feeTokensCount)
        external
        view
        returns (uint256, uint256);
}