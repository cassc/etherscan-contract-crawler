// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IGSWVersionsRegistry {
    /// @notice             checks if an address is listed as allowed GSW version and reverts if it is not
    /// @param gswVersion_  address of the GSW logic contract to check
    function requireValidGSWVersion(address gswVersion_) external view;

    /// @notice                      checks if an address is listed as allowed GSWForwarder version
    ///                              and reverts if it is not
    /// @param gswForwarderVersion_  address of the GSWForwarder logic contract to check
    function requireValidGSWForwarderVersion(address gswForwarderVersion_) external view;
}