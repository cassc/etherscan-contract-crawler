pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { IMembershipRegistry } from "./IMembershipRegistry.sol";
import { BaseModuleGuards } from "./BaseModuleGuards.sol";

/// @dev Contract guards that helps restrict the access to Core Modules
abstract contract ModuleGuards is BaseModuleGuards {

    /// @dev Validate that a KNOT is an active member of a StakeHouse
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyValidStakeHouseKnot(address _stakeHouse, bytes calldata _blsPubKey) {
        _onlyValidStakeHouseKnot(_stakeHouse, _blsPubKey);
        _;
    }

    /// @dev Validate that a KNOT is associated with a given Stakehouse and has not rage quit (ignoring any kicking)
    modifier onlyKnotThatHasNotRageQuit(address _stakeHouse, bytes calldata _blsPubKey) {
        _onlyStakeHouseKnotThatHasNotRageQuit(_stakeHouse, _blsPubKey);
        _;
    }

    function _onlyStakeHouseKnotThatHasNotRageQuit(address _stakeHouse, bytes calldata _blsPubKey) internal view virtual {
        require(!IMembershipRegistry(_stakeHouse).hasMemberRageQuit(_blsPubKey), "Rage Quit");
    }

    function _onlyValidStakeHouseKnot(address _stakeHouse, bytes calldata _blsPubKey) internal view virtual {
        require(IMembershipRegistry(_stakeHouse).isActiveMember(_blsPubKey), "Invalid knot");
    }
}