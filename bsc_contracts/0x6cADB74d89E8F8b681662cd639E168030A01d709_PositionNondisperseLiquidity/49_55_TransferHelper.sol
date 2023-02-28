// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function transferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        token.transferFrom(from, to, value);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }

    /// @notice check approve with token and spender
    /// @param token need check approve
    /// @param spender need grant permit to transfer token
    /// @return bool type after check
    function isApprove(address token, address spender)
        internal
        view
        returns (bool)
    {
        return
            IERC20(token).allowance(address(this), spender) > 0 ? true : false;
    }

    /// @notice approve token with spender
    /// @param token need  approve
    /// @param spender need grant permit to transfer token
    function approve(address token, address spender) internal {
        IERC20(token).approve(spender, type(uint256).max);
    }
}