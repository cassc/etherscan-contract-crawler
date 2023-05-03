// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/IWETH.sol";

contract TransferHelper {
    using SafeERC20 for IERC20;

    IWETH public immutable WNATIVE;

    constructor(IWETH wnative) {
        WNATIVE = wnative;
    }

    /// @notice Wrap the msg.value into the Wrapped Native token
    /// @return wNative The IERC20 representation of the wrapped asset
    /// @return amount Amount of native tokens wrapped
    function _wrapNative() internal returns (IERC20 wNative, uint256 amount) {
        wNative = IERC20(address(WNATIVE));
        amount = msg.value;
        WNATIVE.deposit{value: amount}();
    }

    /// @notice Unwrap current balance of Wrapped Native tokens
    /// @return amount Amount of native tokens unwrapped
    function _unwrapNative() internal returns (uint256 amount) {
        amount = _getBalance(IERC20(address(WNATIVE)));
        IWETH(WNATIVE).withdraw(amount);
    }

    function _transferIn(IERC20 token, uint256 amount) internal returns (uint256 inputAmount) {
        if (amount == 0) return 0;
        uint256 balanceBefore = _getBalance(token);
        token.safeTransferFrom(msg.sender, address(this), amount);
        inputAmount = _getBalance(token) - balanceBefore;
    }

    function _transferOut(IERC20 token, uint256 amount, address to, bool native) internal {
        if (amount == 0) return;
        if (address(token) == address(WNATIVE) && native) {
            IWETH(WNATIVE).withdraw(amount);
            // 2600 COLD_ACCOUNT_ACCESS_COST plus 2300 transfer gas - 1
            // Intended to support transfers to contracts, but not allow for further code execution
            (bool success, ) = to.call{value: amount, gas: 4899}("");
            require(success, "native transfer error");
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function _getBalance(IERC20 token) internal view returns (uint256 balance) {
        balance = token.balanceOf(address(this));
    }
}