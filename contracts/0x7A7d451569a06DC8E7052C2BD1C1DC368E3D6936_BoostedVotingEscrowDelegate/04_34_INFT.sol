// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external;

    function burn(
        uint256 tokenId,
        uint256 label,
        bytes32 data
    ) external;
}