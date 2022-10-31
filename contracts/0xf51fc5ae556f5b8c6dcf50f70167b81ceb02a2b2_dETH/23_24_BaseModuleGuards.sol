pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import { StakeHouseUniverse } from "./StakeHouseUniverse.sol";

/// @dev Contract guards that helps restrict the access to Core Modules
abstract contract BaseModuleGuards {

    /// @notice Address of the smart contract containing source of truth for all deployed contracts
    StakeHouseUniverse public universe;

    /// @dev Only allow registered core modules of the StakeHouse protocol to make a function call
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyModule() {
        _onlyModule();
        _;
    }

    /// @dev Only allow StakeHouse that has been deployed by the StakeHouse universe smart contract (there is no other source of truth)
    /// @dev To save GAS, proxy through to an internal function to save the code being copied in many places and bloating contracts
    modifier onlyValidStakeHouse(address _stakeHouse) {
        _onlyValidStakeHouse(_stakeHouse);
        _;
    }

    function _onlyModule() internal view virtual {
        // Ensure the sender is a core module in the StakeHouse universe
        require(
            universe.accessControls().isCoreModule(msg.sender),
            "Only core"
        );
    }

    function _onlyValidStakeHouse(address _stakeHouse) internal view virtual {
        // Ensure we are interacting with a legitimate StakeHouse from the universe
        require(
            universe.stakeHouseToKNOTIndex(_stakeHouse) > 0,
            "Invalid StakeHouse"
        );
    }

    /// @dev Init the module guards by supplying the address of the valid StakeHouse universe contract
    function __initModuleGuards(StakeHouseUniverse _universe) internal {
        require(address(_universe) != address(0), "Init Err");
        universe = _universe;
    }
}