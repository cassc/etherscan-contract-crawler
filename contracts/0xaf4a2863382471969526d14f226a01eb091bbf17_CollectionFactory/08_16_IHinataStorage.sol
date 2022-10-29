// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IHinataStorage {
    function mintAirdropNFT(
        address receiver,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintArtistNFT(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}