// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Solid World
interface IBlacklist {
    error InvalidBlacklister();
    error BlacklistingNotAuthorized(address caller);

    event BlacklisterUpdated(address indexed oldBlacklister, address indexed newBlacklister);
    event Blacklisted(address indexed subject);
    event UnBlacklisted(address indexed subject);

    function setBlacklister(address newBlacklister) external;

    function blacklist(address subject) external;

    function unBlacklist(address subject) external;

    function getBlacklister() external view returns (address);

    function isBlacklisted(address subject) external view returns (bool);
}