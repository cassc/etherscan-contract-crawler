// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Required interface for the service registry.
interface IServiceRegistry {
    enum UnitType {
        Component,
        Agent
    }

    /// @dev Checks if the service Id exists.
    /// @param serviceId Service Id.
    /// @return true if the service exists, false otherwise.
    function exists(uint256 serviceId) external view returns (bool);

    /// @dev Gets the full set of linearized components / canonical agent Ids for a specified service.
    /// @notice The service must be / have been deployed in order to get the actual data.
    /// @param serviceId Service Id.
    /// @return numUnitIds Number of component / agent Ids.
    /// @return unitIds Set of component / agent Ids.
    function getUnitIdsOfService(UnitType unitType, uint256 serviceId) external view
        returns (uint256 numUnitIds, uint32[] memory unitIds);

    /// @dev Gets the value of slashed funds from the service registry.
    /// @return amount Drained amount.
    function slashedFunds() external view returns (uint256 amount);

    /// @dev Drains slashed funds.
    /// @return amount Drained amount.
    function drain() external returns (uint256 amount);
}