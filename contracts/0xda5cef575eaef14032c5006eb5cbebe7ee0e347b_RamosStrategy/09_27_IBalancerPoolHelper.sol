pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/amo/helpers/IBalancerPoolHelper.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBalancerVault } from "contracts/interfaces/external/balancer/IBalancerVault.sol";
import { IBalancerHelpers } from "contracts/interfaces/external/balancer/IBalancerHelpers.sol";

interface IBalancerPoolHelper {

    function balancerVault() external view returns (IBalancerVault);
    function balancerHelpers() external view returns (IBalancerHelpers);
    function bptToken() external view returns (IERC20);
    function protocolToken() external view returns (IERC20);
    function quoteToken() external view returns (IERC20);
    function amo() external view returns (address);
    
    function BPS_PRECISION() external view returns (uint256);
    function PRICE_PRECISION() external view returns (uint256);

    // @notice protocolToken index in balancer pool
    function protocolTokenIndexInBalancerPool() external view returns (uint64);
    function balancerPoolId() external view returns (bytes32);

    function getBalances() external view returns (uint256[] memory balances);

    function getPairBalances() external view returns (uint256 protocolTokenBalance, uint256 quoteTokenBalance);

    function getSpotPrice() external view returns (uint256 spotPriceScaled);

    function isSpotPriceBelowTpi(uint256 treasuryPriceIndex) external view returns (bool);

    function isSpotPriceBelowTpi(uint256 slippage, uint256 treasuryPriceIndex) external view returns (bool);

    function isSpotPriceBelowTpiLowerBound(uint256 rebalancePercentageBoundLow, uint256 treasuryPriceIndex) external view returns (bool);

    function isSpotPriceAboveTpiUpperBound(uint256 rebalancePercentageBoundUp, uint256 treasuryPriceIndex) external view returns (bool);
    
    function isSpotPriceAboveTpi(uint256 slippage, uint256 treasuryPriceIndex) external view returns (bool);

    function isSpotPriceAboveTpi(uint256 treasuryPriceIndex) external view returns (bool);

    // @notice will exit take price above TPI by a percentage
    // percentage in bps
    // tokensOut: expected min amounts out. for rebalance this is expected `ProtocolToken` tokens out
    function willExitTakePriceAboveTpiUpperBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundUp,
        uint256 treasuryPriceIndex
    ) external view returns (bool);

    function willQuoteTokenJoinTakePriceAboveTpiUpperBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundUp,
        uint256 treasuryPriceIndex
    ) external view returns (bool);

    function willQuoteTokenExitTakePriceBelowTpiLowerBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundLow,
        uint256 treasuryPriceIndex
    ) external view returns (bool);

    function willJoinTakePriceBelowTpiLowerBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundLow,
        uint256 treasuryPriceIndex
    ) external view returns (bool);

    function getSlippage(uint256 spotPriceBeforeScaled) external view returns (uint256);

    function exitPool(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 rebalancePercentageBoundLow,
        uint256 rebalancePercentageBoundUp,
        uint256 postRebalanceDelta,
        uint256 exitTokenIndex,
        uint256 treasuryPriceIndex,
        IERC20 exitPoolToken
    ) external returns (uint256 amountOut);

    function joinPool(
        uint256 amountIn,
        uint256 minBptOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 treasuryPriceIndex,
        uint256 postRebalanceDelta,
        uint256 joinTokenIndex,
        IERC20 joinPoolToken
    ) external returns (uint256 bptIn);

    /// @notice Get the quote used to add liquidity proportionally
    /// @dev Since this is not the view function, this should be called with `callStatic`
    function proportionalAddLiquidityQuote(
        uint256 quoteTokenAmount,
        uint256 slippageBps
    ) external returns (
        uint256 protocolTokenAmount,
        uint256 expectedBptAmount,
        uint256 minBptAmount,
        IBalancerVault.JoinPoolRequest memory requestData
    );

    /// @notice Get the quote used to remove liquidity
    /// @dev Since this is not the view function, this should be called with `callStatic`
    function proportionalRemoveLiquidityQuote(
        uint256 bptAmount,
        uint256 slippageBps
    ) external returns (
        uint256 expectedProtocolTokenAmount,
        uint256 expectedQuoteTokenAmount,
        uint256 minProtocolTokenAmount,
        uint256 minQuoteTokenAmount,
        IBalancerVault.ExitPoolRequest memory requestData
    );

    function applySlippage(uint256 amountIn, uint256 slippageBps) external view returns (uint256 amountOut);

}