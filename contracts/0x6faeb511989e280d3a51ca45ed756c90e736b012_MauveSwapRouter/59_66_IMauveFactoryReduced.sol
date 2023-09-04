// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title A reduced version of the interface for the Mauve Factory
/// @notice The Mauve Factory facilitates creation of Mauve pools and control over the protocol fees
interface IMauveFactoryReduced {
    /// @notice Returns the current address registered as a role on the factory
    /// @dev Can be called by anyone
    /// @param roleKey The selected role to be retrieved from the factory
    /// @return The address of the respective roleKey
    function roles(bytes32 roleKey) external view returns (address);

    /// @notice Returns the current Mauve Compliance Regime
    /// @dev This defines the set of VioletID tokens that an account must own to be compliant with Mauve
    /// @return The list of VioletID tokens that are required under the Mauve Compliance Regime
    function getMauveComplianceRegime() external view returns (uint256[] memory);
}