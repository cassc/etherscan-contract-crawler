// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IHandler {
    function nodeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function plotTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getAttribute(uint256 tokenId)
        external
        view
        returns (string memory);

    function getNodeTypesNames() external view returns (string[] memory);

    function getTokenIdNodeTypeName(uint256 key)
        external
        view
        returns (string memory);

    function nft() external view returns (address);
}