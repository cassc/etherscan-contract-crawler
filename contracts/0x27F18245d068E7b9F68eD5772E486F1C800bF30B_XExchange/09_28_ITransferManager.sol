// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferManager {
    function transferNFT(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address from,
        address to
    ) external;
}