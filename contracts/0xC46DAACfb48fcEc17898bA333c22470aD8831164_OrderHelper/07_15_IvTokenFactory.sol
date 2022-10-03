// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title vToken factory interface
/// @notice Contains vToken creation logic
interface IvTokenFactory {
    event VTokenCreated(address vToken, address asset);

    /// @notice Initialize vToken factory with the given params
    /// @param _registry Index registry address
    /// @param _vTokenImpl Address of vToken implementation
    function initialize(address _registry, address _vTokenImpl) external;

    /// @notice Upgrades beacon implementation
    /// @param _vTokenImpl Address of vToken implementation
    function upgradeBeaconTo(address _vTokenImpl) external;

    /// @notice Creates vToken for the given asset
    /// @param _asset Asset to create vToken for
    function createVToken(address _asset) external;

    /// @notice Creates and returns or returns address of previously created vToken for the given asset
    /// @param _asset Asset to create or return vToken for
    function createdVTokenOf(address _asset) external returns (address);

    /// @notice Returns beacon address
    /// @return Beacon address
    function beacon() external view returns (address);

    /// @notice Returns vToken for the given asset
    /// @param _asset Asset to retrieve vToken for
    /// @return vToken for the given asset
    function vTokenOf(address _asset) external view returns (address);
}