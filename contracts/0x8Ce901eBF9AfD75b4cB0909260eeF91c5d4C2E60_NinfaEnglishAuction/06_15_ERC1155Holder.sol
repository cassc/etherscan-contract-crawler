// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens, but the onERC1155BatchReceived was removed.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 */
contract ERC1155Holder {
    /**
     *
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * param operator The address which initiated the transfer (i.e. msg.sender)
     * param from The address which previously owned the token
     * param id The ID of the token being transferred
     * param value The amount of tokens being transferred
     * param data Additional data with no specified format
     * return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61; // this.onERC1155Received.selector
    }
}