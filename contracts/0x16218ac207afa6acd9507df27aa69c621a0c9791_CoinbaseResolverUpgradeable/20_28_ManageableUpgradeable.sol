// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "openzeppelin/access/OwnableUpgradeable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is a manager account (a signer manager, or a gateway manager) that
 * can be granted exclusive access to specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlySignerManager` and `onlyGatewayManager`, which can be applied to your
 * functions to restrict their use to the signer manager and the gateway
 * manager respectively.
 */
abstract contract ManageableUpgradeable is OwnableUpgradeable {
    /// @dev Address of the signer manager.
    address private _signerManager;
    /// @dev Address of the gateway manager.
    address private _gatewayManager;

    // function initialize() public onlyInitializing {
    //     OwnableUpgradeable.
    // }

    /// @notice Event raised when a signer manager is updated.
    event SignerManagerChanged(
        address indexed previousSignerManager,
        address indexed newSignerManager
    );

    /// @notice Event raised when a gateway manager is updated.
    event GatewayManagerChanged(
        address indexed previousGatewayManager,
        address indexed newGatewayManager
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Managable_init() internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @notice Returns the address of the current signer manager.
     * @return address the signer manager address.
     */
    function signerManager() external view virtual returns (address) {
        return _signerManager;
    }

    /**
     * @notice Returns the address of the current gateway manager.
     * @return address the gateway manager address.
     */
    function gatewayManager() external view virtual returns (address) {
        return _gatewayManager;
    }

    /**
     * @dev Throws if called by any account other than the signer manager.
     */
    modifier onlySignerManager() {
        require(
            _signerManager == _msgSender(),
            "Manageable::onlySignerManager: caller is not signer manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the gateway manager.
     */
    modifier onlyGatewayManager() {
        require(
            _gatewayManager == _msgSender(),
            "Manageable::onlyGatewayManager: caller is not gateway manager"
        );
        _;
    }

    /**
     * @notice Change signer manager of the contract to a new account (`newSignerManager`).
     * @dev Can only be called by the current owner.
     * @param newSignerManager the new signer manager address.
     */
    function changeSignerManager(address newSignerManager)
        external
        virtual
        onlyOwner
    {
        require(
            newSignerManager != address(0),
            "Manageable::changeSignerManager: manager is the zero address"
        );
        _changeSignerManager(newSignerManager);
    }

    /**
     * @notice Change gateway manager of the contract to a new account (`newGatewayManager`).
     * @dev Can only be called by the current owner.
     * @param newGatewayManager the new gateway manager address.
     */
    function changeGatewayManager(address newGatewayManager)
        external
        virtual
        onlyOwner
    {
        require(
            newGatewayManager != address(0),
            "Manageable::changeGatewayManager: manager is the zero address"
        );
        _changeGatewayManager(newGatewayManager);
    }

    /**
     * @notice Change signer manager of the contract to a new account (`newSignerManager`).
     * @dev Internal function without access restriction.
     * @param newSignerManager the new signer manager address.
     */
    function _changeSignerManager(address newSignerManager) internal virtual {
        address oldSignerManager = _signerManager;
        _signerManager = newSignerManager;
        emit SignerManagerChanged(oldSignerManager, newSignerManager);
    }

    /**
     * @notice Change gateway manager of the contract to a new account (`newGatewayManager`).
     * @dev Internal function without access restriction.
     * @param newGatewayManager the new gateway manager address.
     */
    function _changeGatewayManager(address newGatewayManager) internal virtual {
        address oldGatewayManager = _gatewayManager;
        _gatewayManager = newGatewayManager;
        emit GatewayManagerChanged(oldGatewayManager, newGatewayManager);
    }
}