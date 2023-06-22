// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        token.safeTransfer(to, value);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        token.safeTransferFrom(from, to, value);
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        token.approve(spender, 0);
        token.approve(spender, value);
    }

    function infinityApprove(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) <= type(uint256).max / 2) {
            safeApprove(token, spender, type(uint256).max);
        }
    }

    function requireERC20(address tokenAddr) internal view {
        require(IERC20(tokenAddr).totalSupply() > 0, "INVALID_ERC20");
    }

    function requireERC20(IERC20 token) internal view {
        require(token.totalSupply() > 0, "INVALID_ERC20");
    }
}