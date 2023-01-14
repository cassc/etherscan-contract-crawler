// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ISynthAdapter.sol";
import "../interfaces/external/IWETH.sol";
import "../lib/WadRayMath.sol";

contract SynthAdapter is ISynthAdapter {
    using WadRayMath for uint256;

    IPool public immutable pool;
    IWETH public immutable nativeToken;

    constructor(IPool pool_, IWETH nativeToken_) {
        pool = pool_;
        nativeToken = nativeToken_;
    }

    function swap(
        uint256 amountIn_,
        ISyntheticToken _tokenIn,
        ISyntheticToken _tokenOut
    ) external payable returns (uint256 _amountOut) {
        if (amountIn_ == type(uint256).max) {
            amountIn_ = _tokenIn.balanceOf(address(this));
        }
        _amountOut = pool.swap(_tokenIn, _tokenOut, amountIn_);
    }

    function withdraw(uint256 amount_, IDepositToken depositToken_, address to_) external payable {
        if (amount_ == type(uint256).max) {
            amount_ = depositToken_.unlockedBalanceOf(address(this));
        }
        depositToken_.withdraw(amount_, to_);
    }

    function deposit(uint256 amount_, IDepositToken depositToken_, address onBehalfOf_) external payable {
        address _underlying = address(depositToken_.underlying());
        if (_underlying == address(nativeToken)) {
            nativeToken.deposit{value: address(this).balance}();
        }

        if (amount_ == type(uint256).max) {
            amount_ = _underlying == address(nativeToken)
                ? address(this).balance
                : IERC20(_underlying).balanceOf(address(this));
        }

        depositToken_.deposit(amount_, onBehalfOf_);
    }

    function issue(IDebtToken debtToken_, uint256 amount_) external payable {
        debtToken_.issue(amount_, address(this));
    }

    // Note: Issuing all, won't be a problem if repay in the same transaction
    function issueAll(IDebtToken debtToken_) external payable {
        (, , , , uint256 _issuableInUsd) = pool.debtPositionOf(address(this));
        debtToken_.issue(
            IMasterOracle(pool.masterOracle()).quoteUsdToToken(address(debtToken_.syntheticToken()), _issuableInUsd),
            address(this)
        );
    }

    function repayAll(IDebtToken debtToken_) external payable {
        debtToken_.repayAll(address(this));
    }

    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external payable {
        uint256 _amountToRepay = Math.min(
            pool.quoteLiquidateMax(syntheticToken_, account_, depositToken_),
            syntheticToken_.balanceOf(address(this))
        );
        pool.liquidate(syntheticToken_, account_, _amountToRepay, depositToken_);
    }
}