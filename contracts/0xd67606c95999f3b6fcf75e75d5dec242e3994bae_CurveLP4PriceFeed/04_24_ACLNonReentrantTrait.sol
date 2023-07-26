// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AddressProvider } from "./AddressProvider.sol";
import { IACL } from "../interfaces/IACL.sol";
import { ZeroAddressException, CallerNotConfiguratorException, CallerNotPausableAdminException, CallerNotUnPausableAdminException, CallerNotControllerException } from "../interfaces/IErrors.sol";

/// @title ACL Trait
/// @notice Utility class for ACL consumers
abstract contract ACLNonReentrantTrait is Pausable {
    uint8 private constant _NOT_ENTERED = 1;
    uint8 private constant _ENTERED = 2;

    // ACL contract to check rights
    IACL public immutable _acl;

    address public controller;
    bool public externalController;

    uint8 private _status = _NOT_ENTERED;

    /// @dev Modifier that allow pausable admin to call the function if pause is needed
    /// and for unpausable admins if unpause is needed
    /// @param callToPause True if pause action is needed
    modifier pausableUnpausableAdminsOnly(bool callToPause) {
        if (callToPause && !_acl.isPausableAdmin(msg.sender)) {
            revert CallerNotPausableAdminException();
        } else if (!callToPause && !_acl.isUnpausableAdmin(msg.sender)) {
            revert CallerNotUnPausableAdminException();
        }

        _;
    }

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    ///
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    event NewController(address indexed newController);

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        if (addressProvider == address(0)) revert ZeroAddressException(); // F:[AA-2]

        _acl = IACL(AddressProvider(addressProvider).getACL());
        controller = IACL(AddressProvider(addressProvider).getACL()).owner();
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        if (!_acl.isConfigurator(msg.sender)) {
            revert CallerNotConfiguratorException();
        }
        _;
    }

    /// @dev  Reverts if msg.sender is not external controller (if it is set) or configurator
    modifier controllerOnly() {
        if (externalController) {
            if (msg.sender != controller) {
                revert CallerNotControllerException();
            }
        } else {
            if (!_acl.isConfigurator(msg.sender)) {
                revert CallerNotControllerException();
            }
        }
        _;
    }

    ///@dev Pause contract
    function pause() external {
        if (!_acl.isPausableAdmin(msg.sender)) {
            revert CallerNotPausableAdminException();
        }
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        if (!_acl.isUnpausableAdmin(msg.sender)) {
            revert CallerNotUnPausableAdminException();
        }

        _unpause();
    }

    function setController(address newController) external configuratorOnly {
        externalController = !_acl.isConfigurator(newController);
        controller = newController;
        emit NewController(newController);
    }
}