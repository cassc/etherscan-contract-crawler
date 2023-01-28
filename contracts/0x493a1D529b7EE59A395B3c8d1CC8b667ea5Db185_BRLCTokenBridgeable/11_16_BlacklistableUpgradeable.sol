// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title BlacklistableUpgradeable base contract
 * @author CloudWalk Inc.
 * @dev Allows to blacklist and unblacklist accounts using the `blacklister` account.
 *
 * This contract is used through inheritance. It makes available the modifier `notBlacklisted`,
 * which can be applied to functions to restrict their usage to not blacklisted accounts only.
 */
abstract contract BlacklistableUpgradeable is OwnableUpgradeable {
    /// @dev The address of the blacklister that is allowed to blacklist and unblacklist accounts.
    address private _blacklister;

    /// @dev Mapping of presence in the blacklist for a given address.
    mapping(address => bool) private _blacklisted;

    // -------------------- Events -----------------------------------

    /// @dev Emitted when an account is blacklisted.
    event Blacklisted(address indexed account);

    /// @dev Emitted when an account is unblacklisted.
    event UnBlacklisted(address indexed account);

    /// @dev Emitted when an account is self blacklisted.
    event SelfBlacklisted(address indexed account);

    /// @dev Emitted when the blacklister is changed.
    event BlacklisterChanged(address indexed newBlacklister);

    // -------------------- Errors -----------------------------------

    /// @dev The message sender is not a blacklister.
    error UnauthorizedBlacklister(address account);

    /// @dev The account is blacklisted.
    error BlacklistedAccount(address account);

    // -------------------- Modifiers --------------------------------

    /**
     * @dev Throws if called by any account other than the blacklister.
     */
    modifier onlyBlacklister() {
        if (_msgSender() != _blacklister) {
            revert UnauthorizedBlacklister(_msgSender());
        }
        _;
    }

    /**
     * @dev Throws if called by a blacklisted account.
     * @param account The address to check for presence in the blacklist.
     */
    modifier notBlacklisted(address account) {
        if (_blacklisted[account]) {
            revert BlacklistedAccount(account);
        }
        _;
    }

    // -------------------- Functions --------------------------------

    /**
     * @dev The internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function __Blacklistable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __Blacklistable_init_unchained();
    }

    /**
     * @dev The unchained internal initializer of the upgradable contract.
     *
     * See {BlacklistableUpgradeable-__Blacklistable_init}.
     */
    function __Blacklistable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Adds an account to the blacklist.
     *
     * Requirements:
     *
     * - Can only be called by the blacklister account.
     *
     * Emits a {Blacklisted} event.
     *
     * @param account The address to blacklist.
     */
    function blacklist(address account) external onlyBlacklister {
        if (_blacklisted[account]) {
            return;
        }

        _blacklisted[account] = true;

        emit Blacklisted(account);
    }

    /**
     * @dev Removes an account from the blacklist.
     *
     * Requirements:
     *
     * - Can only be called by the blacklister account.
     *
     * Emits an {UnBlacklisted} event.
     *
     * @param account The address to remove from the blacklist.
     */
    function unBlacklist(address account) external onlyBlacklister {
        if (!_blacklisted[account]) {
            return;
        }

        _blacklisted[account] = false;

        emit UnBlacklisted(account);
    }

    /**
     * @dev Adds the message sender to the blacklist.
     *
     * Emits a {SelfBlacklisted} event.
     * Emits a {Blacklisted} event.
     */
    function selfBlacklist() external {
        address sender = _msgSender();

        if (_blacklisted[sender]) {
            return;
        }

        _blacklisted[sender] = true;

        emit SelfBlacklisted(sender);
        emit Blacklisted(sender);
    }

    /**
     * @dev Updates the blacklister address.
     *
     * Requirements:
     *
     * - Can only be called by the contract owner.
     *
     * Emits a {BlacklisterChanged} event.
     *
     * @param newBlacklister The address of a new blacklister.
     */
    function setBlacklister(address newBlacklister) external onlyOwner {
        if (_blacklister == newBlacklister) {
            return;
        }

        _blacklister = newBlacklister;

        emit BlacklisterChanged(_blacklister);
    }

    /**
     * @dev Returns the blacklister address.
     */
    function blacklister() public view virtual returns (address) {
        return _blacklister;
    }

    /**
     * @dev Checks if an account is blacklisted.
     * @param account The address to check for presence in the blacklist.
     * @return True if the account is present in the blacklist.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }
}