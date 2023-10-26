// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBondedToken {
    function lock(
        uint256 tokenId,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    function merge(uint256 tokenIdA, uint256 tokenIdB) external;

    function addBoostedBalance(uint256 tokenId, uint256 amount) external;

    function getLockedOf(uint256 tokenId, address[] memory tokens)
        external
        view
        returns (uint256[] memory amounts);

    function boostedBalance(uint256 tokenId)
        external
        view
        returns (uint256 amount);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mintAndLock(
        address[] memory tokens,
        uint256[] memory amounts,
        address to
    ) external returns (uint256 tokenId);
}