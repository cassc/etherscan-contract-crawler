// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IERC721AfterTokenTransferHandler {
    /**
     * Handles after token transfer events from a ERC721 contract with newer OpenZepplin ERC721Consecutive implementation
     */
    function afterTokenTransfer(
        address tokenContract,
        address operator,
        address from,
        address to,
        uint256 firstId,
        uint256 batchSize
    ) external;
}