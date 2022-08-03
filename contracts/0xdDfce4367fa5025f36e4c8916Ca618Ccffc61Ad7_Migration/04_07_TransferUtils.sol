// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferUtils {
    error TransferUtils__TransferDidNotSucceed();
    error TransferUtils__ApproveDidNotSucceed();

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, amount));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = address(token).call(data);
        if (!success || result.length > 0) {
            // Return data is optional
            bool transferSucceeded = abi.decode(result, (bool));
            if (!transferSucceeded) revert TransferUtils__TransferDidNotSucceed();
        }
    }
}