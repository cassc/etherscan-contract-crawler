// SPDX-License-Identifier: CC0
pragma solidity ^0.8.10;

/**
 * @dev Required interface of an ERC4907 compliant contract.
 */
interface IERC4907 {
    /**
     * @notice Emits when the `user` or the `expires` is changed
     */
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    /**
     * @notice Set the user and an expiration time of an NFT
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /**
     * @notice Query the current user of an NFT
     * @dev The zero address indicates that there is no user
     */
    function userOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Query the end time of the current rental period
     * @dev The zero value indicates that there is no user
     */
    function userExpires(uint256 tokenId) external view returns (uint256);
}