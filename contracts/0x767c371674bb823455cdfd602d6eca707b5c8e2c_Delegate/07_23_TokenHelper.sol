// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./ECDSA.sol";

import "./NativeClaimer.sol";

library TokenHelper {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using Address for address;
    using Address for address payable;
    using NativeClaimer for NativeClaimer.State;

    /**
     * @dev Paxoswap's native coin representation.
     */
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier whenNonZero(uint256 amount_) {
        if (amount_ == 0) {
            return;
        }
        _;
    }

    function isNative(address token_) internal pure returns (bool) {
        return token_ == NATIVE_TOKEN;
    }

    function balanceOf(
        address token_,
        address owner_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        if (isNative(token_)) {
            balance = _nativeBalanceOf(owner_, claimer_);
        } else {
            balance = IERC20(token_).balanceOf(owner_);
        }
    }

    function balanceOfThis(
        address token_,
        NativeClaimer.State memory claimer_
    ) internal view returns (uint256 balance) {
        balance = balanceOf(token_, _this(), claimer_);
    }

    function transferToThis(
        address token_,
        address from_,
        uint256 amount_,
        NativeClaimer.State memory claimer_
    ) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            // We cannot claim native coins of an arbitrary "from_" address
            // like we do with ERC-20 allowance. So the only way to use native
            // is to pass via "value" with the contract call. The "from_" address
            // does not participate in such a scenario. The only thing we can do
            // is to restrict caller to be "from_" address only.
            require(from_ == _sender(), "TH: native allows sender only");
            claimer_.claim(amount_);
        } else {
            IERC20(token_).safeTransferFrom(from_, _this(), amount_);
        }
    }

    function transferFromThis(address token_, address to_, uint256 amount_) internal whenNonZero(amount_) {
        if (isNative(token_)) {
            _nativeTransferFromThis(to_, amount_);
        } else {
            IERC20(token_).safeTransfer(to_, amount_);
        }
    }

    function approveOfThis(
        address token_,
        address spender_,
        uint256 amount_
    ) internal whenNonZero(amount_) returns (uint256 sendValue) {
        if (isNative(token_)) {
            sendValue = amount_;
        } else {
            sendValue = 0;
            IERC20(token_).safeApprove(spender_, amount_);
        }
    }

    function revokeOfThis(address token_, address spender_) internal {
        if (!isNative(token_)) {
            IERC20(token_).safeApprove(spender_, 0);
        }
    }

    function _nativeBalanceOf(
        address owner_,
        NativeClaimer.State memory claimer_
    ) private view returns (uint256 balance) {
        if (owner_ == _sender()) {
            balance = claimer_.unclaimed();
        } else {
            balance = owner_.balance;
            if (owner_ == _this()) {
                balance -= claimer_.unclaimed();
            }
        }
    }

    function _nativeTransferFromThis(address to_, uint256 amount_) private whenNonZero(amount_) {
        payable(to_).sendValue(amount_);
    }

    function _this() private view returns (address) {
        return address(this);
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }
}