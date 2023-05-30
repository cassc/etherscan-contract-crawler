//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategyToken.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategy is IStrategyToken, StrategyTypes {
    function approveToken(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveDebt(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveSynths(
        address account,
        uint256 amount
    ) external;

    function setStructure(StrategyItem[] memory newItems) external;

    function setCollateral(address token) external;

    function withdrawAll(uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external returns (uint256);

    function delegateSwap(
        address adapter,
        uint256 amount,
        address tokenIn,
        address tokenOut
    ) external;

    function settleSynths() external;

    function issueStreamingFee() external;

    function updateTokenValue(uint256 total, uint256 supply) external;

    function updatePerformanceFee(uint16 fee) external;

    function updateRebalanceThreshold(uint16 threshold) external;

    function updateTradeData(address item, TradeData memory data) external;

    function lock() external;

    function unlock() external;

    function locked() external view returns (bool);

    function items() external view returns (address[] memory);

    function synths() external view returns (address[] memory);

    function debt() external view returns (address[] memory);

    function rebalanceThreshold() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function getPercentage(address item) external view returns (int256);

    function getTradeData(address item) external view returns (TradeData memory);

    function getPerformanceFeeOwed(address account) external view returns (uint256);

    function controller() external view returns (address);

    function manager() external view returns (address);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);

    function supportsSynths() external view returns (bool);
}