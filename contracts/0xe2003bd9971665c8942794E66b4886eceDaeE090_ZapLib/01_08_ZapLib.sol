// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ICurve.sol";

library ZapLib {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct ZapData {
        address curve;
        address base;
        address quote;
        uint256 zapAmount;
        uint256 curveBaseBal;
        uint8 curveBaseDecimals;
        uint256 curveQuoteBal;
    }

    struct DepositData {
        address curve;
        address base;
        address quote;
        uint256 curBaseAmount;
        uint256 curQuoteAmount;
        uint256 maxBaseAmount;
        uint256 maxQuoteAmount;
    }

    /// @notice Zaps from a single token into the LP pool
    /// @param _curve The address of the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param _deadline Deadline for this zap to be completed by
    /// @param _minLPAmount Min LP amount to get
    /// @param isFromBase Is the zap originating from the base? (if base, then not USDC)
    function zap(
        address _curve,
        uint256 _zapAmount,
        uint256 _deadline,
        uint256 _minLPAmount,
        bool isFromBase
    ) public {
        address base = ICurve(_curve).reserves(0);
        address quote = ICurve(_curve).reserves(1);
        uint256 swapAmount = calcSwapAmountForZap(
            _curve,
            base,
            quote,
            _zapAmount,
            isFromBase
        );

        // Swap on curve
        if (isFromBase) {
            IERC20(base).safeTransferFrom(
                msg.sender,
                address(this),
                _zapAmount
            );
            IERC20(base).safeApprove(_curve, 0);
            IERC20(base).safeApprove(_curve, swapAmount);

            ICurve(_curve).originSwap(base, quote, swapAmount, 0, _deadline);
        } else {
            IERC20(quote).safeTransferFrom(
                msg.sender,
                address(this),
                _zapAmount
            );
            IERC20(quote).safeApprove(_curve, 0);
            IERC20(quote).safeApprove(_curve, swapAmount);

            ICurve(_curve).originSwap(quote, base, swapAmount, 0, _deadline);
        }

        // Calculate deposit amount
        uint256 baseAmount = IERC20(base).balanceOf(address(this));
        uint256 quoteAmount = IERC20(quote).balanceOf(address(this));
        (uint256 depositAmount, , ) = _calcDepositAmount(
            DepositData({
                curve: _curve,
                base: base,
                quote: quote,
                curBaseAmount: baseAmount,
                curQuoteAmount: quoteAmount,
                maxBaseAmount: baseAmount,
                maxQuoteAmount: quoteAmount
            })
        );

        // Can only deposit the smaller amount as we won't have enough of the
        // token to deposit
        IERC20(base).safeApprove(_curve, 0);
        IERC20(base).safeApprove(_curve, baseAmount);

        IERC20(quote).safeApprove(_curve, 0);
        IERC20(quote).safeApprove(_curve, quoteAmount);

        (uint256 lpAmount, ) = ICurve(_curve).deposit(depositAmount, _deadline);
        require(lpAmount >= _minLPAmount, "ZapLib/not-enough-lp-amount");
    }

    /// @notice Iteratively calculates how much to swap
    /// @param _curve The address of the curve
    /// @param _base The base address in the curve
    /// @param _quote The quote address in the curve
    /// @param _zapAmount The amount to zap, denominated in the ERC20's decimal placing
    /// @param isFromBase Is the swap originating from the base?
    /// @return uint256 - The amount to swap
    function calcSwapAmountForZap(
        address _curve,
        address _base,
        address _quote,
        uint256 _zapAmount,
        bool isFromBase
    ) public view returns (uint256) {
        // Ratio of base quote in 18 decimals
        uint256 curveBaseBal = IERC20(_base).balanceOf(_curve);
        uint8 curveBaseDecimals = ERC20(_base).decimals();
        uint256 curveQuoteBal = IERC20(_quote).balanceOf(_curve);

        // How much user wants to swap
        uint256 initialSwapAmount = _zapAmount.div(2);

        // Calc Base Swap Amount
        if (isFromBase) {
            return (
                _calcBaseSwapAmount(
                    initialSwapAmount,
                    ZapData({
                        curve: _curve,
                        base: _base,
                        quote: _quote,
                        zapAmount: _zapAmount,
                        curveBaseBal: curveBaseBal,
                        curveBaseDecimals: curveBaseDecimals,
                        curveQuoteBal: curveQuoteBal
                    })
                )
            );
        }

        // Calc quote swap amount
        return (
            _calcQuoteSwapAmount(
                initialSwapAmount,
                ZapData({
                    curve: _curve,
                    base: _base,
                    quote: _quote,
                    zapAmount: _zapAmount,
                    curveBaseBal: curveBaseBal,
                    curveBaseDecimals: curveBaseDecimals,
                    curveQuoteBal: curveQuoteBal
                })
            )
        );
    }

    /// @notice Calculate how many quote tokens needs to be swapped into base tokens to
    ///         respect the pool's ratio
    /// @param initialSwapAmount The initial amount to swap
    /// @param zapData           Zap data encoded
    /// @return uint256 - The amount of quote tokens to be swapped into base tokens
    function _calcQuoteSwapAmount(
        uint256 initialSwapAmount,
        ZapData memory zapData
    ) public view returns (uint256) {
        uint256 swapAmount = initialSwapAmount;
        uint256 delta = initialSwapAmount.div(2);
        uint256 recvAmount;
        uint256 curveRatio;
        uint256 userRatio;

        // Computer bring me magic number
        for (uint256 i = 0; i < 32; i++) {
            // How much will we receive in return
            recvAmount = ICurve(zapData.curve).viewOriginSwap(
                zapData.quote,
                zapData.base,
                swapAmount
            );

            // Update user's ratio
            userRatio = recvAmount
                .mul(10**(36 - uint256(zapData.curveBaseDecimals)))
                .div(zapData.zapAmount.sub(swapAmount).mul(1e12));
            curveRatio = zapData
                .curveBaseBal
                .sub(recvAmount)
                .mul(10**(36 - uint256(zapData.curveBaseDecimals)))
                .div(zapData.curveQuoteBal.add(swapAmount).mul(1e12));

            // If user's ratio is approx curve ratio, then just swap
            // I.e. ratio converges
            if (userRatio.div(1e16) == curveRatio.div(1e16)) {
                return swapAmount;
            }
            // Otherwise, we keep iterating
            else if (userRatio > curveRatio) {
                // We swapping too much
                swapAmount = swapAmount.sub(delta);
            } else if (userRatio < curveRatio) {
                // We swapping too little
                swapAmount = swapAmount.add(delta);
            }

            // Cannot swap more than zapAmount
            if (swapAmount > zapData.zapAmount) {
                swapAmount = zapData.zapAmount - 1;
            }

            // Keep halving
            delta = delta.div(2);
        }

        revert("ZapLib/not-converging");
    }

    /// @notice Calculate how many base tokens needs to be swapped into quote tokens to
    ///         respect the pool's ratio
    /// @param initialSwapAmount The initial amount to swap
    /// @param zapData           Zap data encoded
    /// @return uint256 - The amount of base tokens to be swapped into quote tokens
    function _calcBaseSwapAmount(
        uint256 initialSwapAmount,
        ZapData memory zapData
    ) public view returns (uint256) {
        uint256 swapAmount = initialSwapAmount;
        uint256 delta = initialSwapAmount.div(2);
        uint256 recvAmount;
        uint256 curveRatio;
        uint256 userRatio;

        // Computer bring me magic number
        for (uint256 i = 0; i < 32; i++) {
            // How much will we receive in return
            recvAmount = ICurve(zapData.curve).viewOriginSwap(
                zapData.base,
                zapData.quote,
                swapAmount
            );

            // Update user's ratio
            userRatio = zapData
                .zapAmount
                .sub(swapAmount)
                .mul(10**(36 - uint256(zapData.curveBaseDecimals)))
                .div(recvAmount.mul(1e12));
            curveRatio = zapData
                .curveBaseBal
                .add(swapAmount)
                .mul(10**(36 - uint256(zapData.curveBaseDecimals)))
                .div(zapData.curveQuoteBal.sub(recvAmount).mul(1e12));

            // If user's ratio is approx curve ratio, then just swap
            // I.e. ratio converges
            if (userRatio.div(1e16) == curveRatio.div(1e16)) {
                return swapAmount;
            }
            // Otherwise, we keep iterating
            else if (userRatio > curveRatio) {
                // We swapping too little
                swapAmount = swapAmount.add(delta);
            } else if (userRatio < curveRatio) {
                // We swapping too much
                swapAmount = swapAmount.sub(delta);
            }

            // Cannot swap more than zap
            if (swapAmount > zapData.zapAmount) {
                swapAmount = zapData.zapAmount - 1;
            }

            // Keep halving
            delta = delta.div(2);
        }

        revert("ZapLib/not-converging");
    }

    /// @notice Given a DepositData structure, calculate the max depositAmount, the max
    ///          LP tokens received, and the required amounts
    /// @param _curve The address of the curve
    /// @param _base  The base address in the curve
    /// @param _quote The quote address in the curve
    /// @param dd     Deposit data

    /// @return uint256 - The deposit amount
    /// @return uint256 - The LPTs received
    /// @return uint256[] memory - The baseAmount and quoteAmount
    function _calcDepositAmount(DepositData memory dd)
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        // Calculate _depositAmount
        uint8 curveBaseDecimals = ERC20(dd.base).decimals();
        uint256 curveRatio = IERC20(dd.base)
            .balanceOf(dd.curve)
            .mul(10**(36 - uint256(curveBaseDecimals)))
            .div(IERC20(dd.quote).balanceOf(dd.curve).mul(1e12));

        // Deposit amount is denomiated in USD value (based on pool LP ratio)
        // Things are 1:1 on USDC side on deposit
        uint256 usdcDepositAmount = dd.curQuoteAmount.mul(1e12);

        // Things will be based on ratio on deposit
        uint256 baseDepositAmount = dd.curBaseAmount.mul(
            10**(18 - uint256(curveBaseDecimals))
        );

        // Trim out decimal values
        uint256 depositAmount = usdcDepositAmount.add(
            baseDepositAmount.mul(1e18).div(curveRatio)
        );
        depositAmount = _roundDown(depositAmount);

        // // Make sure we have enough of our inputs
        (uint256 lps, uint256[] memory outs) = ICurve(dd.curve).viewDeposit(
            depositAmount
        );

        uint256 baseDelta = outs[0] > dd.maxBaseAmount
            ? outs[0].sub(dd.curBaseAmount)
            : 0;
        uint256 usdcDelta = outs[1] > dd.maxQuoteAmount
            ? outs[1].sub(dd.curQuoteAmount)
            : 0;

        // Make sure we can deposit
        if (baseDelta > 0 || usdcDelta > 0) {
            dd.curBaseAmount = _roundDown(dd.curBaseAmount.sub(baseDelta));
            dd.curQuoteAmount = _roundDown(dd.curQuoteAmount.sub(usdcDelta));

            return _calcDepositAmount(dd);
        }

        return (depositAmount, lps, outs);
    }

    // Stack too deep
    function _roundDown(uint256 a) public pure returns (uint256) {
        return a.mul(99999999).div(100000000);
    }
}