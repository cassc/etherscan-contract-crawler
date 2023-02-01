// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title BEP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BEP721 asset contracts.
 */
interface IBEP721Receiver {
    /**
     * @dev Whenever an {IBEP721} `tokenId` token is transferred to this contract via {IBEP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBEP721.onBEP721Received.selector`.
     */
    function onBEP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}