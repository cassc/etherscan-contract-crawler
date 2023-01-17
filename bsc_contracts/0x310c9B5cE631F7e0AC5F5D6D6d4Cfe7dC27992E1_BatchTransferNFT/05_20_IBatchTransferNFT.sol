// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBatchTransferNFT {
    struct Transfer {
        address nft;
        address recipient;
        uint256 tokenId;
        uint256 amount;
    }

    function batchTransfer(Transfer[] calldata _transfers) external;
}