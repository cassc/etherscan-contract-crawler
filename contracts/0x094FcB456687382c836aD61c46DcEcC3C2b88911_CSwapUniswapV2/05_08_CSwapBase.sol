// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "SafeERC20.sol";

abstract contract CSwapBase {
    using SafeERC20 for IERC20;

    function _getContractName() internal pure virtual returns (string memory);

    function _revertMsg(string memory message) internal {
        revert(string(abi.encodePacked(_getContractName(), ":", message)));
    }

    function _requireMsg(bool condition, string memory message) internal {
        if (!condition) {
            revert(string(abi.encodePacked(_getContractName(), ":", message)));
        }
    }

    function _tokenApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }

    function _preSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address router,
        uint256 amount,
        address receiver
    ) internal virtual returns (uint256 balanceBefore) {
        balanceBefore = tokenOut.balanceOf(receiver);
        _tokenApprove(tokenIn, router, amount);
    }

    function _postSwap(
        uint256 balanceBefore,
        IERC20 tokenOut,
        uint256 minReceived,
        address receiver
    ) internal virtual {
        uint256 balanceAfter = tokenOut.balanceOf(address(receiver));
        _requireMsg(balanceAfter >= balanceBefore + minReceived, "Slippage in");
    }
}