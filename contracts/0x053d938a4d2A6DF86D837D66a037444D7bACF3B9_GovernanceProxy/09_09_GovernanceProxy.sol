// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC1967Proxy } from "@openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";
import { FrankenDAOErrors } from "../errors/FrankenDAOErrors.sol";

/// @title FrankenDAO Governance Proxy
/// @author Zach Obront & Zakk Fleischmann
/** @dev This contract is similar to OZ's TransparentUpgradeableProxy, but it:
- allows Admin to access the fallback function (so that Executor can call implementation functions)
- changes ifAdmin modifier to onlyAdmin, reverting vs fallback if non admin calls a proxy function
- gives non admin ability to access proxy view functions: admin() and implementation() */
contract GovernanceProxy is ERC1967Proxy, FrankenDAOErrors {

    /////////////////////////////
    //////// CONSTRUCTOR ////////
    /////////////////////////////

    /// @notice Initializes an upgradeable proxy
    /// @param _logic Implementation contract the proxy will fall back to
    /// @param admin_ Address that has access to write functions on the proxy contract
    /// @param _data Calldata that will be used to initialize the contract
    constructor (address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /////////////////////////////
    ///////// MODIFIERS /////////
    /////////////////////////////

    /// @notice Modifier used to protect admin functions on this proxy contract
    modifier onlyAdmin() {
        if (msg.sender != _getAdmin()) revert NotAuthorized();
        _;
    }
    
    /////////////////////////////
    /////// VIEW FUNCTIONS //////
    /////////////////////////////

    /// @notice Returns the current admin.
    /** @dev TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
    eth_getStorageAt RPC call: `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103` */
    function admin() external view returns (address admin_) {
        admin_ = _getAdmin();
    }

    /// @notice Returns the current implementation.
    /** @dev TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
    eth_getStorageAt RPC call: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` */
    function implementation() external view returns (address implementation_) {
        implementation_ = _implementation();
    }

    /////////////////////////////
    ////// ADMIN FUNCTIONS //////
    /////////////////////////////

    /// @notice Changes the admin of the proxy.
    /// @param newAdmin Address of the new admin
    function changeAdmin(address newAdmin) external virtual onlyAdmin {
        _changeAdmin(newAdmin);
    }

    /// @notice Upgrades the implementation of the proxy.
    /// @param newImplementation Address of the new implementation
    function upgradeTo(address newImplementation) external onlyAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /// @notice Upgrades the implementation of the proxy and calls the new implementation with the provided data.
    /// @param newImplementation Address of the new implementation
    /// @param data Data to send as msg.data in the low level call. This should be encoded calldata for a function call to the new implementation.
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable onlyAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }
}