// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICubeXCard {
    function balanceOf(address _owner) external view returns (uint256);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function getOwnerTokens(
        address _owner
    ) external view returns (uint256[] memory);
}