// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/// @title IZoraModuleManager
/// @author sweetman.eth <[email protected]>
/// @notice This contract allows users to approve registered modules on ZORA V3
interface IZoraModuleManager {
    /// @notice Returns true if the user has approved a given module, false otherwise
    /// @param _user The user to check approvals for
    /// @param _module The module to check approvals for
    /// @return True if the module has been approved by the user, false otherwise
    function isModuleApproved(address _user, address _module)
        external
        view
        returns (bool);

    /// @notice Allows a user to set the approval for a given module
    /// @param _module The module to approve
    /// @param _approved A boolean, whether or not to approve a module
    function setApprovalForModule(address _module, bool _approved) external;

    /// @notice Sets approvals for multiple modules at once
    /// @param _modules The list of module addresses to set approvals for
    /// @param _approved A boolean, whether or not to approve the modules
    function setBatchApprovalForModules(
        address[] memory _modules,
        bool _approved
    ) external;

    /// @notice Sets approval for a module given an EIP-712 signature
    /// @param _module The module to approve
    /// @param _user The user to approve the module for
    /// @param _approved A boolean, whether or not to approve a module
    /// @param _deadline The deadline at which point the given signature expires
    /// @param _v The 129th byte and chain ID of the signature
    /// @param _r The first 64 bytes of the signature
    /// @param _s Bytes 64-128 of the signature
    function setApprovalForModuleBySig(
        address _module,
        address _user,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /// @notice Registers a module
    /// @param _module The address of the module
    function registerModule(address _module) external;

    /// @notice Sets the registrar for the ZORA Module Manager
    /// @param _registrar the address of the new registrar
    function setRegistrar(address _registrar) external;
}