//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.17;

import "oz-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Enforcement module.
 *
 * Allows the issuer to freeze transfers from a given address
 */
abstract contract FreezableUpgradeable is Initializable
{
    /**
     * @notice Emitted when an address is frozen.
     */
    event Freeze(
        address indexed enforcer,
        address indexed owner,
        string indexed reasonIndexed,
        string reason
    );

    /**
     * @notice Emitted when an address is unfrozen.
     */
    event Unfreeze(
        address indexed enforcer,
        address indexed owner,
        string indexed reasonIndexed,
        string reason
    );

    error InvalidAccount(address account);

    mapping(address => bool) private _frozen;

    function __Freezable_init() internal onlyInitializing {}

    /**
     * @dev Returns true if the account is frozen, and false otherwise.
     */
    function frozen(address account) public view virtual returns (bool) {
        return _frozen[account];
    }

    /**
     * @dev Freezes an address.
     * @dev Override with access control.
     * @param account the account to freeze
     * @param reason indicate why the account was frozen.
     *
     */
    function _freeze(
        address account,
        string calldata reason
    ) internal virtual returns (bool) {
        if (account == address(0)) {
            revert InvalidAccount(account);
        }
        if (_frozen[account]) {
            return false;
        }
        _frozen[account] = true;
        emit Freeze(msg.sender, account, reason, reason);
        return true;
    }

    /**
     * @dev Unfreezes an address.
     * @dev Override with access control.
     * @param account the account to unfreeze
     * @param reason indicate why the account was unfrozen.
     */
    function _unfreeze(
        address account,
        string calldata reason
    ) internal virtual returns (bool) {
        if (account == address(0)) {
            revert InvalidAccount(account);
        }
        if (!_frozen[account]) {
            return false;
        }
        _frozen[account] = false;
        emit Unfreeze(msg.sender, account, reason, reason);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}