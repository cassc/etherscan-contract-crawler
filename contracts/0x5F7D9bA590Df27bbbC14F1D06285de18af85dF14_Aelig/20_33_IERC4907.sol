// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC4907 {
    struct AccountInfo {
        address account;
        uint256 expires;
    }

    struct FrameInfo {
        uint256 frameId;
        uint256 expires;
    }

    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /**
        @notice Set the user and expires of an NFT. The user cannot upload or clear the frame. The owner cannot either.
        @dev The zero address indicates there is no user throws if `tokenId` is not valid NFT
        @param user  The new user of the NFT
        @param expires  UNIX timestamp, The new user could use the NFT before expires
    */
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /**
        @notice Get the user address of an NFT
        @dev The zero address indicates that there is no user or the user is expired
        @param tokenId The NFT to get the user address for
        @return The user address for this NFT
    */
    function userOf(uint256 tokenId) external view returns(address);

    /**
        @notice Get the user expires of an NFT
        @dev The zero value indicates that there is no user
        @param tokenId The NFT to get the user expires for
        @return The user expires for this NFT
    */
    function userExpires(uint256 tokenId) external view returns(uint256);
}