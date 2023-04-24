// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts.
 * @notice Contract module based on Ownable which provides a basic access
 *         control mechanism, where there is an owner and a manager that can be
 *         granted exclusive access to specific functions.
 *
 *         The `owner` is first set by passing the address of the `initialOwner`
 *         to the Ownable constructor.
 *
 *         The owner account can be transferred through a two steps process:
 *         1. The current `owner` calls {transferOwnership} to set a
 *            `pendingOwner`.
 *         2. The `pendingOwner` calls {acceptOwnership} to accept the ownership
 *            transfer.
 *
 *         The manager account needs to be set using {setManager}.
 *
 *         This module is used through inheritance. It will make available the
 *         modifiers `onlyManager`, `onlyOwner` and `onlyManagerOrOwner`, which
 *         can be applied to your functions to restrict their use to the manager
 *         and/or the owner.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    function __Manageable_init_unchained(
        address _initialOwner
    ) internal onlyInitializing {
        __Ownable_init_unchained(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(
            _newManager != _previousManager,
            "Manageable/existing-manager-address"
        );

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);

        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(
            manager() == msg.sender || owner() == msg.sender,
            "Manageable/caller-not-manager-or-owner"
        );
        _;
    }

    uint256[45] private __gap;
}