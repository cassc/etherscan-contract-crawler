// SPDX-License-Identifier: Unlicense
// Version 0.0.1

pragma solidity ^0.8.17;

interface IEve {
    function mintNormal(
        address to_,
        uint256 quantity_
    ) external returns (uint256[] memory);

    function mintMythic(
        address to_,
        uint256 quantity_
    ) external returns (uint256[] memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function exists(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);

    function nextMythicTokenId() external view returns (uint256);
}