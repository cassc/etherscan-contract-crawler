// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { VariablesV1 } from "./VariablesV1.sol";

error SelfUpgradeable__Unauthorized();

/// @title      SelfUpgradeable
/// @notice     Simple contract to upgrade the implementation address stored at storage slot 0x0
/// @dev        Mostly based on OpenZeppelin ERC1967Upgrade contract, adapted with selfCall etc.
///             IMPORANT to keep VariablesV1 at first inheritance to ensure proxy impl address is at 0x0
abstract contract SelfUpgradeable is VariablesV1 {
    /// @notice Emitted when the implementation is upgraded to a new GSW logic contract
    event Upgraded(address indexed gswImpl);

    /// @notice modifier that ensures the method can only be called by the same contract itself
    modifier onlySelf() {
        _requireSelfCalled();
        _;
    }

    /// @notice             upgrade the contract to a new implementation address, if valid version
    ///                     can only be called by contract itself (in case of GSW through `cast`)
    /// @param gswImpl_     New contract address
    function upgradeTo(address gswImpl_) public onlySelf {
        gswVersionsRegistry.requireValidGSWVersion(gswImpl_);

        _gswImpl = gswImpl_;
        emit Upgraded(gswImpl_);
    }

    /// @notice             upgrade the contract to a new implementation address, if valid version
    ///                     and call a function afterwards
    ///                     can only be called by contract itself (in case of GSW through `cast`)
    /// @param gswImpl_     New contract address
    /// @param data_        callData for function call on gswImpl_ after upgrading
    /// @param forceCall_   optional flag to force send call even if callData (data_) is empty
    function upgradeToAndCall(
        address gswImpl_,
        bytes calldata data_,
        bool forceCall_
    ) external payable virtual onlySelf {
        upgradeTo(gswImpl_);
        if (data_.length > 0 || forceCall_) {
            Address.functionDelegateCall(gswImpl_, data_);
        }
    }

    /// @dev internal method for modifier logic to reduce bytecode size of contract
    function _requireSelfCalled() internal view {
        if (msg.sender != address(this)) {
            revert SelfUpgradeable__Unauthorized();
        }
    }
}