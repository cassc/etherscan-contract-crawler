// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {ZeroAddressException, CallerNotConfiguratorException, CallerNotPausableAdminException, CallerNotUnPausableAdminException} from "../interfaces/IErrors.sol";

/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL public immutable _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        if (addressProvider == address(0)) revert ZeroAddressException(); // F:[AA-2]

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        if (!_acl.isConfigurator(msg.sender))
            revert CallerNotConfiguratorException();
        _;
    }

    ///@dev Pause contract
    function pause() external {
        if (!_acl.isPausableAdmin(msg.sender))
            revert CallerNotPausableAdminException();
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        if (!_acl.isUnpausableAdmin(msg.sender))
            revert CallerNotUnPausableAdminException();

        _unpause();
    }
}