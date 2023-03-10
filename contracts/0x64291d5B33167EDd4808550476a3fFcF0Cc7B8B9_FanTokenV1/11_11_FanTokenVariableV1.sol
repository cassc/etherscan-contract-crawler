// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FanTokenVariableV1 is ERC20Upgradeable, OwnableUpgradeable {
    // lock counter for creating lock id
    uint256 public lockCounter;

    // lock struct to store lock details.
    struct Locks {
        uint256 lockId;
        address user;
        uint256 lockAmount;
        uint256 lockDuration;
    }

    // mapping lock struct with lock id.
    mapping(uint256 => Locks) public lockDetails;

    // blacklisted address mapping
    mapping(address => bool) public isblacklistedAccount;

    // mapping of address with their owned lock Ids
    mapping(address => uint256[]) public userLocks;

    // gap for future variables (upgrades)
    uint256[50] __gap;

    // admin eoa wallet
    address public adminEOAWallet;

    // Events

    /**
     * @dev Emitted when new lock is created.
     */
    event LockCreated(uint256 lockId, address to, uint256 quantity, uint256 duration);

    /**
     * @dev Emitted when lock is modified.
     */
    event LockModified(uint256 lockid, uint256 duration);

    /**
     * @dev Emitted when trusted forwarder address is modified.
     */
    event TrustedForwarderModified(address forwarder);

    /**
     * @dev Emitted when account is blacklisted or whitelisted
     */
    event BlacklistedAccount(address account, bool status);

    /**
     * @dev Emitted when admin EOA wallet is modified.
     */
    event SetAdminEOAWallet(address newAdminEOAWallet);
}