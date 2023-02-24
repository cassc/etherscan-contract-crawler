// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "../oz/token/ERC20/IERC20.sol";

error Transferable__TransferFailed();
error Transferable__InvalidArguments();

/**
 * @dev Library for transferring Ether and tokens between accounts
 */
abstract contract Transferable {
    /**
     * @dev Reverts the transaction if the transfer fails
     * @param token_ Address of the token contract to transfer. If zero address, transfer Ether.
     * @param from_ Address to transfer from
     * @param to_ Address to transfer to
     * @param value_ Amount of tokens or Ether to transfer
     */
    function _safeTransferFrom(
        address token_,
        address from_,
        address to_,
        uint256 value_,
        bytes memory data_
    ) internal virtual {
        __checkValidTransfer(to_, value_);

        if (
            token_ == address(0)
                ? _nativeTransfer(to_, value_, data_)
                : _ERC20TransferFrom(IERC20(token_), from_, to_, value_)
        ) return;

        revert Transferable__TransferFailed();
    }

    /**
     * @dev Reverts the transaction if the transfer fails
     * @param token_ Address of the token contract to transfer. If zero address, transfer Ether.
     * @param to_ Address to transfer to
     * @param value_ Amount of tokens or Ether to transfer
     */
    function _safeTransfer(
        address token_,
        address to_,
        uint256 value_,
        bytes memory data_
    ) internal virtual {
        __checkValidTransfer(to_, value_);

        if (
            token_ == address(0)
                ? _nativeTransfer(to_, value_, data_)
                : _ERC20Transfer(IERC20(token_), to_, value_)
        ) return;

        revert Transferable__TransferFailed();
    }

    /**
     * @dev Reverts the transaction if the Ether transfer fails
     * @param to_ Address to transfer to
     * @param amount_ Amount of Ether to transfer
     */
    function _safeNativeTransfer(
        address to_,
        uint256 amount_,
        bytes memory data_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);
        if (!_nativeTransfer(to_, amount_, data_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20Transfer(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);
        if (!_ERC20Transfer(token_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20TransferFrom(
        IERC20 token_,
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);

        if (!_ERC20TransferFrom(token_, from_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _nativeTransfer(
        address to_,
        uint256 amount_,
        bytes memory data_
    ) internal virtual returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(
                gas(),
                to_,
                amount_,
                add(data_, 32),
                mload(data_),
                0,
                0
            )
        }
    }

    function _ERC20Transfer(
        IERC20 token_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to_) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), value_) // Append the "amount" argument.

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
    }

    function _ERC20TransferFrom(
        IERC20 token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            let freeMemoryPointer := mload(0x40)

            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from_)
            mstore(add(freeMemoryPointer, 36), to_)
            mstore(add(freeMemoryPointer, 68), value_)

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 100, 0, 32)
            )
        }
    }

    function __checkValidTransfer(address to_, uint256 value_) private pure {
        if (to_ == address(0) || value_ == 0)
            revert Transferable__InvalidArguments();
    }
}