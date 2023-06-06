// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IVault
 * @notice Interface for the BaseVault
 */
interface IVault {

    /**
     * @notice Enables/Disables a module.
     * @param _module The target module.
     * @param _value Set to `true` to authorise the module.
     */
    function authoriseModule(address _module, bool _value, bytes memory _initData) external;

    /**
     * @notice Enables a static method by specifying the target module to which the call must be delegated.
     * @param _module The target module.
     */
    function enableStaticCall(address _module) external;


    /**
     * @notice Inits the vault by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules, bytes[] calldata _initData) external;

    /**
     * @notice Sets a new owner for the vault.
     * @param _newOwner The new owner.
     */
    function setOwner(address _newOwner) external;

    /**
     * @notice Returns the vault owner.
     * @return The vault owner address.
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the number of authorised modules.
     * @return The number of authorised modules.
     */
    function modules() external view returns (uint256);

    /**
     * @notice Checks if a module is authorised on the vault.
     * @param _module The module address to check.
     * @return `true` if the module is authorised, otherwise `false`.
     */
    function authorised(address _module) external view returns (bool);

    /**
     * @notice Returns the module responsible, if static call is enabled for `_sig`, otherwise return zero address.
     * @param _sig The signature of the static call.
     * @return the module doing the redirection or zero address
     */
    function enabled(bytes4 _sig) external view returns (address);
}