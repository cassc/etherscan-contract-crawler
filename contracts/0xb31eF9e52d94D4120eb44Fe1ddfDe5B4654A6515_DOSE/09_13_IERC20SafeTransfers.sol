// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, optional extension: Safe Transfers
 * Note: the ERC-165 identifier for this interface is 0x53f41a97.
 */
interface IERC20SafeTransfers {
    /**
     * Transfers tokens from the caller to `to`. If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than the sender's balance.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * Transfers tokens from `from` to another address, using the allowance mechanism.
     *  If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than `from`'s balance.
     * @dev Reverts if the sender does not have at least `value` allowance by `from`.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param from The address which owns the tokens to be transferred.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}