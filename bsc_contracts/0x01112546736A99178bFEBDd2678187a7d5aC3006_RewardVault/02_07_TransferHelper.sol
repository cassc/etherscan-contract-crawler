// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TransferHelper
 * @dev Wrappers around ERC20 operations that returns the value received by recipent and the actual allowance of approval.
 * To use this library you can add a `using TransferHelper for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library TransferHelper {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
            require(success, "TF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (uint256 amountReceived) {
        if (_amount > 0) {
            bool success;
            uint256 balanceBefore = _token.balanceOf(_to);
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
            require(success, "TFF");
            uint256 balanceAfter = _token.balanceOf(_to);
            require(balanceAfter > balanceBefore, "TFF");
            amountReceived = balanceAfter - balanceBefore;
        }
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal returns (uint256) {
        bool success;
        if (_token.allowance(address(this), _spender) != 0) {
            (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, 0));
            require(success, "AF");
        }
        (success, ) = address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _amount));
        require(success, "AF");

        return _token.allowance(address(this), _spender);
    }
}