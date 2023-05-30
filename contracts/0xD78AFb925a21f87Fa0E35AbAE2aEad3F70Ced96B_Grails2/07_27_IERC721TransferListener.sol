// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Grails II
 * @author ERC721 Transfer Listener
 */
interface IERC721TransferListener {
    /**
     * @notice Hook that is called on token transfers.
     */
    function onTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;
}