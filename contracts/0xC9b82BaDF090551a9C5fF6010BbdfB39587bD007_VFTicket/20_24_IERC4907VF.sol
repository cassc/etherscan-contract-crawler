// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC4907VF {
    error ERC4907VFTransferCallerIsNotOwnerNorApproved();
    error ERC4907VFTransactionExpired();
    error ERC4907VFInvalidSignature();

    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    function setSigner(address signer) external;

    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        string calldata orderId,
        uint256 timestamp,
        bytes calldata signature
    ) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);

    /// @notice Get the NFTs of an address in a range
    /// @param user The user address to get the NFTs for
    /// @param startIndex The start index of the range
    /// @param endIndex The end index of the range
    function tokensOfUserIn(
        address user,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (uint256[] memory userTokens);
}