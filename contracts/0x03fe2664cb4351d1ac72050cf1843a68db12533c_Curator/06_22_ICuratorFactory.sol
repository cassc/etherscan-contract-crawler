// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @notice Curator factory allows deploying and setting up new curators
 * @author [email protected]
 */
interface ICuratorFactory {
    /// @notice Emitted when a curator is deployed
    event CuratorDeployed(address curator, address owner, address deployer);
    /// @notice Emitted when a valid upgrade path is registered by the owner
    event RegisteredUpgradePath(address implFrom, address implTo);
    /// @notice Emitted when a new metadata renderer is set
    event HasNewMetadataRenderer(address);

    /// @notice Getter to determine if a contract upgrade path is valid.
    function isValidUpgrade(address baseImpl, address newImpl) external view returns (bool);
}