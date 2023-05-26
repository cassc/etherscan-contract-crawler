// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {HandlerBase, IERC20} from "../HandlerBase.sol";
import {IWrappedNativeToken} from "../wrappednativetoken/IWrappedNativeToken.sol";
import {IComet} from "./IComet.sol";

contract HCompoundV3 is HandlerBase {
    address public immutable wrappedNativeToken;

    constructor(address wrappedNativeToken_) {
        wrappedNativeToken = wrappedNativeToken_;
    }

    function getContractName() public pure override returns (string memory) {
        return "HCompoundV3";
    }

    function supply(
        address comet,
        address asset,
        uint256 amount
    ) external payable {
        _requireMsg(amount != 0, "supply", "zero amount");
        amount = _getBalance(asset, amount);
        _supply(
            comet,
            _getSender(), // Return to msg.sender
            asset,
            amount
        );
    }

    function supplyETH(address comet, uint256 amount) external payable {
        _requireMsg(amount != 0, "supplyETH", "zero amount");
        amount = _getBalance(NATIVE_TOKEN_ADDRESS, amount);
        IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();

        _supply(
            comet,
            _getSender(), // Return to msg.sender
            wrappedNativeToken,
            amount
        );
        _updateToken(wrappedNativeToken);
    }

    function withdraw(
        address comet,
        address asset,
        uint256 amount
    ) external payable returns (uint256 withdrawAmount) {
        _requireMsg(amount != 0, "withdraw", "zero amount");

        // No _getBalance: because we use comet.allow() to help users withdraw
        bool isBorrowed;
        (withdrawAmount, isBorrowed) = _withdraw(
            comet,
            _getSender(), // from
            asset,
            amount
        );

        // Borrow is not allowed
        _requireMsg(!isBorrowed, "withdraw", "borrow");
        _updateToken(asset);
    }

    function withdrawETH(
        address comet,
        uint256 amount
    ) external payable returns (uint256 withdrawAmount) {
        _requireMsg(amount != 0, "withdrawETH", "zero amount");

        // No _getBalance: because we use comet.allow() to help users withdraw
        bool isBorrowed;
        (withdrawAmount, isBorrowed) = _withdraw(
            comet,
            _getSender(), // from
            wrappedNativeToken,
            amount
        );

        // Borrow is not allowed
        _requireMsg(!isBorrowed, "withdrawETH", "borrow");
        IWrappedNativeToken(wrappedNativeToken).withdraw(withdrawAmount);
    }

    function borrow(
        address comet,
        uint256 amount
    ) external payable returns (uint256 borrowAmount) {
        _requireMsg(amount != 0, "borrow", "zero amount");

        bool isBorrowed;
        address baseToken = IComet(comet).baseToken();
        (borrowAmount, isBorrowed) = _withdraw(
            comet,
            _getSender(), // from
            baseToken,
            amount
        );

        // Withdrawal is not allowed
        _requireMsg(isBorrowed, "borrow", "withdraw");
        _updateToken(baseToken);
    }

    function borrowETH(
        address comet,
        uint256 amount
    ) external payable returns (uint256 borrowAmount) {
        _requireMsg(
            IComet(comet).baseToken() == wrappedNativeToken,
            "borrowETH",
            "wrong comet"
        );
        _requireMsg(amount != 0, "borrowETH", "zero amount");

        bool isBorrowed;
        (borrowAmount, isBorrowed) = _withdraw(
            comet,
            _getSender(), // from
            wrappedNativeToken,
            amount
        );

        // Withdrawal is not allowed
        _requireMsg(isBorrowed, "borrowETH", "withdraw");
        IWrappedNativeToken(wrappedNativeToken).withdraw(borrowAmount);
    }

    function repay(address comet, uint256 amount) external payable {
        _requireMsg(amount != 0, "repay", "zero amount");

        address asset = IComet(comet).baseToken();
        amount = _getBalance(asset, amount);
        _supply(
            comet,
            _getSender(), // to
            asset,
            amount
        );
    }

    function repayETH(address comet, uint256 amount) external payable {
        _requireMsg(
            IComet(comet).baseToken() == wrappedNativeToken,
            "repayETH",
            "wrong comet"
        );
        _requireMsg(amount != 0, "repayETH", "zero amount");

        amount = _getBalance(NATIVE_TOKEN_ADDRESS, amount);
        IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();
        _supply(
            comet,
            _getSender(), // to
            wrappedNativeToken,
            amount
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _supply(
        address comet,
        address dst,
        address asset,
        uint256 amount
    ) internal {
        _tokenApprove(asset, comet, amount);
        try IComet(comet).supplyTo(dst, asset, amount) {} catch Error(
            string memory reason
        ) {
            _revertMsg("supply", reason);
        } catch {
            _revertMsg("supply");
        }
        _tokenApproveZero(asset, comet);
    }

    function _withdraw(
        address comet,
        address from,
        address asset,
        uint256 amount
    ) internal returns (uint256 withdrawAmount, bool isBorrowed) {
        uint256 beforeBalance = IERC20(asset).balanceOf(address(this));
        uint256 borrowBalanceBefore = IComet(comet).borrowBalanceOf(from);

        try
            IComet(comet).withdrawFrom(
                from,
                address(this), // to
                asset,
                amount
            )
        {
            withdrawAmount =
                IERC20(asset).balanceOf(address(this)) -
                beforeBalance;
            isBorrowed =
                IComet(comet).borrowBalanceOf(from) > borrowBalanceBefore;
        } catch Error(string memory reason) {
            _revertMsg("withdraw", reason);
        } catch {
            _revertMsg("withdraw");
        }
    }
}