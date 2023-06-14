// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../AugustusStorage.sol";
import "../lib/Utils.sol";
import "./IFeeClaimer.sol";
// helpers
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeModel is AugustusStorage {
    using SafeMath for uint256;

    uint256 public immutable partnerSharePercent;
    uint256 public immutable maxFeePercent;
    uint256 public immutable paraswapReferralShare;
    uint256 public immutable paraswapSlippageShare;
    IFeeClaimer public immutable feeClaimer;

    constructor(
        uint256 _partnerSharePercent,
        uint256 _maxFeePercent,
        uint256 _paraswapReferralShare,
        uint256 _paraswapSlippageShare,
        IFeeClaimer _feeClaimer
    ) {
        partnerSharePercent = _partnerSharePercent;
        maxFeePercent = _maxFeePercent;
        paraswapReferralShare = _paraswapReferralShare;
        paraswapSlippageShare = _paraswapSlippageShare;
        feeClaimer = _feeClaimer;
    }

    // feePercent is a packed structure.
    // Bits 255-248 = 8-bit version field
    //
    // Version 0
    // =========
    // Entire structure is interpreted as the fee percent in basis points.
    // If set to 0 then partner will not receive any fees.
    //
    // Version 1
    // =========
    // Bits 13-0 = Fee percent in basis points
    // Bit 14 = positiveSlippageToUser (positive slippage to partner if not set)
    // Bit 15 = if set, take fee from fromToken, toToken otherwise
    // Bit 16 = if set, do fee distribution as per referral program

    function takeFromTokenFee(
        address fromToken,
        uint256 fromAmount,
        address payable partner,
        uint256 feePercent
    ) internal returns (uint256 newFromAmount) {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        if (fixedFeeBps == 0) return fromAmount;
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(fromAmount, fixedFeeBps);
        return _distributeFees(fromAmount, fromToken, partner, partnerShare, paraswapShare);
    }

    function takeFromTokenFeeAndTransfer(
        address fromToken,
        uint256 fromAmount,
        uint256 remainingAmount,
        address payable partner,
        uint256 feePercent
    ) internal {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(fromAmount, fixedFeeBps);
        if (partnerShare.add(paraswapShare) <= remainingAmount) {
            remainingAmount = _distributeFees(remainingAmount, fromToken, partner, partnerShare, paraswapShare);
        }
        Utils.transferTokens(fromToken, msg.sender, remainingAmount);
    }

    function takeToTokenFeeAndTransfer(
        address toToken,
        uint256 receivedAmount,
        address payable beneficiary,
        address payable partner,
        uint256 feePercent
    ) internal {
        uint256 fixedFeeBps = _getFixedFeeBps(partner, feePercent);
        (uint256 partnerShare, uint256 paraswapShare) = _calcFixedFees(receivedAmount, fixedFeeBps);
        Utils.transferTokens(
            toToken,
            beneficiary,
            _distributeFees(receivedAmount, toToken, partner, partnerShare, paraswapShare)
        );
    }

    function takeSlippageAndTransferSell(
        address toToken,
        address payable beneficiary,
        address payable partner,
        uint256 positiveAmount,
        uint256 negativeAmount,
        uint256 feePercent
    ) internal {
        uint256 totalSlippage = positiveAmount.sub(negativeAmount);
        if (partner != address(0)) {
            (uint256 referrerShare, uint256 paraswapShare) = _calcSlippageFees(totalSlippage, feePercent);
            positiveAmount = _distributeFees(positiveAmount, toToken, partner, referrerShare, paraswapShare);
        } else {
            uint256 paraswapSlippage = totalSlippage.mul(paraswapSlippageShare).div(10000);
            Utils.transferTokens(toToken, feeWallet, paraswapSlippage);
            positiveAmount = positiveAmount.sub(paraswapSlippage);
        }
        Utils.transferTokens(toToken, beneficiary, positiveAmount);
    }

    function takeSlippageAndTransferBuy(
        address fromToken,
        address payable partner,
        uint256 positiveAmount,
        uint256 negativeAmount,
        uint256 remainingAmount,
        uint256 feePercent
    ) internal {
        uint256 totalSlippage = positiveAmount.sub(negativeAmount);
        if (partner != address(0)) {
            (uint256 referrerShare, uint256 paraswapShare) = _calcSlippageFees(totalSlippage, feePercent);
            remainingAmount = _distributeFees(remainingAmount, fromToken, partner, referrerShare, paraswapShare);
        } else {
            uint256 paraswapSlippage = totalSlippage.mul(paraswapSlippageShare).div(10000);
            Utils.transferTokens(fromToken, feeWallet, paraswapSlippage);
            remainingAmount = remainingAmount.sub(paraswapSlippage);
        }
        // Transfer remaining token back to sender
        Utils.transferTokens(fromToken, msg.sender, remainingAmount);
    }

    function _getFixedFeeBps(address partner, uint256 feePercent) internal view returns (uint256 fixedFeeBps) {
        if (partner == address(0)) return 0;
        uint256 version = feePercent >> 248;
        if (version == 0) {
            fixedFeeBps = feePercent;
        } else {
            fixedFeeBps = feePercent & 0x3FFF;
        }
        return fixedFeeBps > maxFeePercent ? maxFeePercent : fixedFeeBps;
    }

    function _calcFixedFees(uint256 amount, uint256 fixedFeeBps)
        private
        view
        returns (uint256 partnerShare, uint256 paraswapShare)
    {
        uint256 fee = amount.mul(fixedFeeBps).div(10000);
        partnerShare = fee.mul(partnerSharePercent).div(10000);
        paraswapShare = fee.sub(partnerShare);
    }

    function _calcSlippageFees(uint256 slippage, uint256 feePercent)
        private
        view
        returns (uint256 partnerShare, uint256 paraswapShare)
    {
        uint256 feeBps = feePercent & 0x3FFF;
        require(feeBps + paraswapReferralShare <= 10000, "Invalid fee percent");
        paraswapShare = slippage.mul(paraswapReferralShare).div(10000);
        partnerShare = slippage.mul(feeBps).div(10000);
    }

    function _distributeFees(
        uint256 currentBalance,
        address token,
        address payable partner,
        uint256 partnerShare,
        uint256 paraswapShare
    ) private returns (uint256 newBalance) {
        uint256 totalFees = partnerShare.add(paraswapShare);
        if (totalFees == 0) return currentBalance;

        require(totalFees <= currentBalance, "Insufficient balance to pay for fees");

        Utils.transferTokens(token, payable(address(feeClaimer)), totalFees);
        if (partnerShare != 0) {
            feeClaimer.registerFee(partner, IERC20(token), partnerShare);
        }
        if (paraswapShare != 0) {
            feeClaimer.registerFee(feeWallet, IERC20(token), paraswapShare);
        }
        return currentBalance.sub(totalFees);
    }

    function _isTakeFeeFromSrcToken(uint256 feePercent) internal pure returns (bool) {
        return feePercent >> 248 != 0 && (feePercent & (1 << 15)) != 0;
    }

    function _isReferral(uint256 feePercent) internal pure returns (bool) {
        return (feePercent & (1 << 16)) != 0;
    }
}