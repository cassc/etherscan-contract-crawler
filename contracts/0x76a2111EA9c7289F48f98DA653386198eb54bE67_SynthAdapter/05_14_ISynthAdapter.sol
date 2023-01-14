// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/external/synth/IPool.sol";
import "../interfaces/external/synth/IDepositToken.sol";
import "../interfaces/external/synth/IDebtToken.sol";

interface ISynthAdapter {
    function withdraw(uint256 amount_, IDepositToken depositToken_, address to_) external payable;

    function deposit(uint256 amount_, IDepositToken depositToken_, address onBehalfOf_) external payable;

    function issueAll(IDebtToken debtToken_) external payable;

    function repayAll(IDebtToken debtToken_) external payable;

    function issue(IDebtToken debtToken_, uint256 amount_) external payable;

    function liquidate(ISyntheticToken syntheticToken_, address account_, IDepositToken depositToken_) external payable;

    function swap(
        uint256 amountIn_,
        ISyntheticToken _tokenIn,
        ISyntheticToken _tokenOut
    ) external payable returns (uint256 _amountOut);

    function pool() external view returns (IPool);
}