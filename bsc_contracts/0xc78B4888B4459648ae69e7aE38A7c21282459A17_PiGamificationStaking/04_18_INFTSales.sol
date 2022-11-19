//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface INFTSales {
    function batchTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds
    ) external;

    function batchSafeTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds,
        bytes memory data
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external;

    function transfer(address to, uint256 tokenId) external returns (bool);
}