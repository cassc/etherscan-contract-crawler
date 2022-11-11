// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMultimetamultiverse {
    /**
     * Events
     */

    event ProjectEdit(uint projectId, uint projectGroupId, address author, uint[4] whitelist, bool onlyWhitelistedUsers, uint[6] royalty, uint mintAmount, uint mintPrice, uint revealTime, string[3] uri, bool mintLocked, uint affiliateDepth);
    event ProjectTokenURIEditorsAdd(uint projectId, address[] editors);
    event ProjectTokenURIEditorsRemove(uint projectId, address[] editors);
    event ProjectWhitelistedUsersAdd(uint projectId, address[] whitelistedUsers);
    event ProjectWhitelistedUsersRemove(uint projectId, address[] whitelistedUsers);

    event ProjectGroupEdit(uint projectGroupId, address author, bool onlyWhitelistedAuthors, bool projectLocked);
    event ProjectGroupWhitelistedAuthorsAdd(uint projectGroupId, address[] whitelistedAuthors);
    event ProjectGroupWhitelistedAuthorsRemove(uint projectGroupId, address[] whitelistedAuthors);

    event TokenEdit(uint tokenId, bool lock, uint price, uint projectId, uint revealTime, uint value);
    event TokenURIEdit(uint tokenId, string uri);

    event MinTokenPriceEdit(uint price);

    event ProjectGroupLockedEdit(bool status);
    event ProjectLockedEdit(bool status);
    event MintLockedEdit(bool status);

    event BannedUsersAdd(address[] bannedUsers);
    event BannedUsersRemove(address[] bannedUsers);

    event WhitelistedAuthorsAdd(address[] whitelistedAuthors);
    event WhitelistedAuthorsRemove(address[] whitelistedAuthors);
    event OnlyWhitelistedAuthorsEdit(bool state);

    event SavingsEdit(address user, uint value);
    event SavingsEditBatch(address[] user, uint[] value);

    /**
     * EIP4907
     */

    // Logged when the user of a token assigns a new user or updates expires
    event UpdateUser(uint indexed tokenId, address indexed user, uint64 expires);

    // Set the user role and expires of a token
    function setUser(uint tokenId, address user, uint64 expires) external;

    // Get the user of a token
    function userOf(uint tokenId) external view returns(address);

    // Get the user expires of a token
    function userExpires(uint tokenId) external view returns(uint);
}