// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./Delegation.sol";

/// @title The LowLevelDelegator allows users to create delegations very cheaply.
contract LowLevelDelegator is Initializable {
    using ClonesUpgradeable for address;

    /// @notice The instance to which all proxies will point.
    Delegation public delegationInstance;

    function __LowLevelDelegator_init_unchained() internal onlyInitializing {
        delegationInstance = new Delegation();
        delegationInstance.initialize(uint96(0));
    }

    /**
     * @notice Creates a clone of the delegation.
     * @param _salt Random number used to deterministically deploy the clone.
     * @param _lockUntil Timestamp until which the delegation is locked.
     * @return The newly created delegation.
     */
    function _createDelegation(
        bytes32 _salt,
        uint96 _lockUntil
    ) internal returns (Delegation) {
        Delegation _delegation = Delegation(
            address(delegationInstance).cloneDeterministic(_salt)
        );

        _delegation.initialize(_lockUntil);

        return _delegation;
    }

    /**
     * @notice Computes the address of a clone, also known as minimal proxy
     *         contract.
     * @param _salt Random number used to compute the address.
     * @return Address at which the clone will be deployed.
     */
    function _computeAddress(bytes32 _salt) internal view returns (address) {
        return
            address(delegationInstance).predictDeterministicAddress(
                _salt,
                address(this)
            );
    }

    /**
     * @notice Computes salt used to deterministically deploy a clone.
     * @param _delegator Address of the delegator.
     * @param _slot Slot of the delegation.
     * @return Salt used to deterministically deploy a clone.
     */
    function _computeSalt(
        address _delegator,
        bytes32 _slot
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_delegator, _slot));
    }

    uint256[45] private __gap;
}