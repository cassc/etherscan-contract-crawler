// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IManageable.sol";
import "./IDepositToken.sol";
import "./IDebtToken.sol";

/**
 * @notice SmartFarmingManager interface
 */
interface ISmartFarmingManager {
    function flashRepay(
        ISyntheticToken syntheticToken_,
        IDepositToken depositToken_,
        uint256 withdrawAmount_,
        uint256 repayAmountMin_
    ) external returns (uint256 _withdrawn, uint256 _repaid);

    function crossChainFlashRepay(
        ISyntheticToken syntheticToken_,
        IDepositToken depositToken_,
        uint256 withdrawAmount_,
        IERC20 bridgeToken_,
        uint256 bridgeTokenAmountMin_,
        uint256 swapAmountOutMin_,
        uint256 repayAmountMin_,
        bytes calldata lzArgs_
    ) external payable;

    function crossChainLeverage(
        IERC20 tokenIn_,
        IDepositToken depositToken_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_,
        uint256 swapAmountOutMin_,
        uint256 depositAmountMin_,
        bytes calldata lzArgs_
    ) external payable;

    function crossChainLeverageCallback(uint256 id_, uint256 swapAmountOut_) external returns (uint256 _deposited);

    function crossChainFlashRepayCallback(uint256 id_, uint256 swapAmountOut_) external returns (uint256 _repaid);

    function leverage(
        IERC20 tokenIn_,
        IDepositToken depositToken_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_,
        uint256 depositAmountMin_
    ) external returns (uint256 _deposited, uint256 _issued);
}