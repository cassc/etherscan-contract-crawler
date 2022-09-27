// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title BlacklistableUpgradeable base contract
 * @dev Allows to blacklist/unblacklist accounts using the `blacklister` role.
 *
 * This contract is used through inheritance. It makes available the modifier `notBlacklisted`,
 * which can be applied to functions to restrict their usage to not blacklisted accounts only.
 *
 * By default, the blacklister is set to the zero address. This can later be changed
 * by the contract owner with the {setBlacklister} function.
 *
 * There is also a possibility to any account to blacklist itself.
 */
abstract contract BlacklistableUpgradeable is OwnableUpgradeable {
    /// @dev The address of the blacklister.
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

    /// @dev The transaction sender is not a blacklister.
    error UnauthorizedBlacklister(address account);

    /// @dev The transaction sender is blacklisted.
    error BlacklistedAccount(address account);

    // -------------------- Functions --------------------------------

    function __Blacklistable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();

        __Blacklistable_init_unchained();
    }

    function __Blacklistable_init_unchained() internal onlyInitializing {}

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

    /**
     * @dev Returns the blacklister address.
     */
    function blacklister() public view virtual returns (address) {
        return _blacklister;
    }

    /**
     * @dev Checks if the account is blacklisted.
     * @param account The address to check for presence in the blacklist.
     * @return True if the account is present in the blacklist.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    /**
     * @dev Adds an account to the blacklist.
     *
     * Requirements:
     *
     * - Can only be called by the blacklister.
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
     * - Can only be called by the blacklister.
     *
     * Emits a {UnBlacklisted} event.
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
     * @dev Adds the transaction sender to the blacklist.
     *
     * Emits a {SelfBlacklisted} event.
     * Emits a {Blacklisted} event.
     */
    function selfBlacklist() external {
        if (_blacklisted[_msgSender()]) {
            return;
        }

        _blacklisted[_msgSender()] = true;

        emit SelfBlacklisted(_msgSender());
        emit Blacklisted(_msgSender());
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
}