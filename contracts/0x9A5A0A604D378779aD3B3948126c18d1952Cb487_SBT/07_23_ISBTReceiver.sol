// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title Soulbound token receiver interface
 */
interface ISBTReceiver {
    /**
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `ISBTReceiver.onSBTReceived.selector`.
     */
    function onSBTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}