// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

import "../interfaces/external/IERC20.sol";

/// @author  https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
/// @notice  Utils functions to transfer tokens and ETH
library TransferHelper {
    /// ERRORS ///

    /// @notice Thrown when a transfer reverts
    error TransferError();

    /// @notice Thrown when an approval reverts
    error ApproveError();

    /// FUNCTIONS ///

    /// @notice       Transfers tokens from the targeted address to the given destination
    /// @param token  Contract address of the token to be transferred
    /// @param from   Originating address from which the tokens will be transferred
    /// @param to     Destination address of the transfer
    /// @param value  Amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );

        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert TransferError();
    }

    /// @notice       Transfers tokens from msg.sender to a recipient
    /// @param token  Contract address of the token which will be transferred
    /// @param to     Recipient of the transfer
    /// @param value  Value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert TransferError();
    }

    /// @notice       Approves the stipulated contract to spend the given allowance in the given token
    /// @param token  Contract address of the token to be approved
    /// @param to     Target of the approval
    /// @param value  Amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) revert ApproveError();
    }

    /// @notice       Transfers ETH to the recipient address
    /// @param to     Destination of the transfer
    /// @param value  Value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (success == false) revert TransferError();
    }
}