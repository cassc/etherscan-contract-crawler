// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMKLockRegistry {
    function isUnlocked(uint256 _id) external view returns (bool);

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external;

    function lock(uint256 _id) external;

    function unlock(uint256 _id, uint256 pos) external;

    function findPos(uint256 _id, address addr) external view returns (uint256);

    function clearLockId(uint256 _id, uint256 pos) external;

    // copy from IERC721.sol to avoid import causing dependency linearization error
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}