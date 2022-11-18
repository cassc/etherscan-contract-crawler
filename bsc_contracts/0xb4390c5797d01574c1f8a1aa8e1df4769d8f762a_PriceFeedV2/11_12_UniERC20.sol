// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

library UniERC20 {
    using SafeERC20 for IERC20;
    /// @notice pseudo address to use inplace of native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(IERC20 token, address holder)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return holder.balance;
        }
        return token.balanceOf(holder);
    }

    function transferTo(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            safeTransferETH(receiver, amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == ETH;
    }

    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}