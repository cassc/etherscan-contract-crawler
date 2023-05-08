// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";

library SafeTransfer {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(s, "safeTransferFrom failed");
    }

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(s, "safeTransfer failed");
    }

    function safeApprove(IERC20 token, address to, uint256 value) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(s, "safeApprove failed");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }
}