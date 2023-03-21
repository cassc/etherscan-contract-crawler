// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC4907 {
    event UpdateUser(
        uint256 indexed tokenID,
        address indexed user,
        uint64 expires
    );

    function setUser(uint256 tokenID, address user, uint64 expires) external;

    function userOf(uint256 tokenID) external view returns (address);

    function userExpires(uint256 tokenID) external view returns (uint256);
}