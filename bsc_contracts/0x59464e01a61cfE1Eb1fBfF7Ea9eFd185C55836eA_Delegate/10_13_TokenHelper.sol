// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NativeClaimer} from "./NativeClaimer.sol";

library TokenHelper {
    using NativeClaimer for NativeClaimer.State;

    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier whenNonZero(uint256 amount_) {
        if (amount_ == 0) return;
        _;
    }

    function isNative(address token_) internal pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    function balanceOf(address token_, address owner_, NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return isNative(token_) ? _nativeBalanceOf(owner_, claimer_) : IERC20(token_).balanceOf(owner_);
    }

    function balanceOfThis(address token_, NativeClaimer.State memory claimer_) internal view returns (uint256) {
        return balanceOf(token_, address(this), claimer_);
    }

    function transferToThis(address token_, address from_, uint256 amount_, NativeClaimer.State memory claimer_) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            require(from_ == msg.sender, "TH: native allows sender only");
            claimer_.claim(amount_);
        } else SafeERC20.safeTransferFrom(IERC20(token_), from_, address(this), amount_);
    }

    function transferFromThis(address token_, address to_, uint256 amount_) internal whenNonZero(amount_) {
        isNative(token_) ? Address.sendValue(payable(to_), amount_) : SafeERC20.safeTransfer(IERC20(token_), to_, amount_);
    }

    function approveOfThis(address token_, address spender_, uint256 amount_) internal whenNonZero(amount_) returns (uint256 sendValue) {
        if (isNative(token_)) sendValue = amount_;
        else SafeERC20.safeApprove(IERC20(token_), spender_, amount_);
    }

    function revokeOfThis(address token_, address spender_) internal {
        if (!isNative(token_)) SafeERC20.safeApprove(IERC20(token_), spender_, 0);
    }

    function _nativeBalanceOf(address owner_, NativeClaimer.State memory claimer_) private view returns (uint256 balance) {
        if (owner_ == msg.sender) balance = claimer_.unclaimed();
        else {
            balance = owner_.balance;
            if (owner_ == address(this)) balance -= claimer_.unclaimed();
        }
    }
}