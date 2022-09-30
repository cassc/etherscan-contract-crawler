// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";
import "./ISwapData.sol";

interface IBaseStrategy {
    function underlying() external view returns (IERC20);

    function getStrategyBalance() external view returns (uint128);

    function getStrategyUnderlyingWithRewards() external view returns(uint128);

    function process(uint256[] calldata, bool, SwapData[] calldata) external;

    function processReallocation(uint256[] calldata, ProcessReallocationData calldata) external returns(uint128);

    function processDeposit(uint256[] calldata) external;

    function fastWithdraw(uint128, uint256[] calldata, SwapData[] calldata) external returns(uint128);

    function claimRewards(SwapData[] calldata) external;

    function emergencyWithdraw(address recipient, uint256[] calldata data) external;

    function initialize() external;

    function disable() external;

    /* ========== EVENTS ========== */

    event Slippage(address strategy, IERC20 underlying, bool isDeposit, uint256 amountIn, uint256 amountOut);
}

struct ProcessReallocationData {
    uint128 sharesToWithdraw;
    uint128 optimizedShares;
    uint128 optimizedWithdrawnAmount;
}