// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./GenericManager.sol";
import "./interfaces/IRegistry.sol";

/// @title Registries Manager - Periphery smart contract for managing components and agents
/// @author Aleksandr Kuperman - <[email protected]>
contract RegistriesManager is GenericManager {
    // Component registry address
    address public immutable componentRegistry;
    // Agent registry address
    address public immutable agentRegistry;

    constructor(address _componentRegistry, address _agentRegistry) {
        componentRegistry = _componentRegistry;
        agentRegistry = _agentRegistry;
        owner = msg.sender;
    }

    /// @dev Creates component / agent.
    /// @param unitType Unit type (component or agent).
    /// @param unitOwner Owner of the component / agent.
    /// @param unitHash IPFS hash of the component / agent.
    /// @param dependencies Set of component dependencies in a sorted ascending order.
    /// @return unitId The id of a created component / agent.
    function create(
        IRegistry.UnitType unitType,
        address unitOwner,
        bytes32 unitHash,
        uint32[] memory dependencies
    ) external returns (uint256 unitId)
    {
        // Check if the creation is paused
        if (paused) {
            revert Paused();
        }
        if (unitType == IRegistry.UnitType.Component) {
            unitId = IRegistry(componentRegistry).create(unitOwner, unitHash, dependencies);
        } else {
            unitId = IRegistry(agentRegistry).create(unitOwner, unitHash, dependencies);
        }
    }

    /// @dev Updates the component / agent hash.
    /// @param unitType Unit type (component or agent).
    /// @param unitId Agent Id.
    /// @param unitHash Updated IPFS hash of the component / agent.
    /// @return success True, if function executed successfully.
    function updateHash(IRegistry.UnitType unitType, uint256 unitId, bytes32 unitHash) external returns (bool success) {
        if (unitType == IRegistry.UnitType.Component) {
            success = IRegistry(componentRegistry).updateHash(msg.sender, unitId, unitHash);
        } else {
            success = IRegistry(agentRegistry).updateHash(msg.sender, unitId, unitHash);
        }
    }
}