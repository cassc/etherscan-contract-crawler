// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAdminRole.sol";
import "../interfaces/INodeRole.sol";
import "../interfaces/IOperatorRole.sol";
import "../interfaces/IModuleRole.sol";

error AddressManagerNode_Address_Is_Not_A_Contract();
error AddressManagerNode_Caller_Not_Admin();
error AddressManagerNode_Caller_Not_Node();
error AddressManagerNode_Caller_Not_Module();
error AddressManagerNode_Caller_Not_Operator();

/**
 * @title A mixin that stores a reference to the CHIZU core contract.
 */
abstract contract AddressManagerNode is Initializable {
    using AddressUpgradeable for address payable;

    /// @notice The address of the core contract.
    address payable internal core;

    /// @notice Requires the caller is a CHIZU admin.
    modifier onlyCHIZUAdmin() {
        if (!IAdminRole(core).isAdmin(msg.sender)) {
            revert AddressManagerNode_Caller_Not_Admin();
        }
        _;
    }

    /// @notice Requires the caller is a CHIZU operator.
    modifier onlyCHIZUOperator() {
        if (!IOperatorRole(core).isOperator(msg.sender)) {
            revert AddressManagerNode_Caller_Not_Operator();
        }
        _;
    }

    /// @notice Requires the caller is a CHIZU operator.
    modifier onlyCHIZUNode() {
        if (!INodeRole(core).isNode(msg.sender)) {
            revert AddressManagerNode_Caller_Not_Node();
        }
        _;
    }

    /// @notice Requires the caller is a CHIZU operator.
    modifier onlyCHIZUModule() {
        if (!IModuleRole(core).isModule(msg.sender)) {
            revert AddressManagerNode_Caller_Not_Module();
        }
        _;
    }

    /**
     * @notice Set immutable variables for the implementation contract.
     * @dev Assigns the core contract address.
     */
    function AddressManagerNode_init(address payable _core)
        internal
        onlyInitializing
    {
        if (!_core.isContract()) {
            revert AddressManagerNode_Address_Is_Not_A_Contract();
        }
        core = _core;
    }

    /**
     * @notice Gets the CHIZU core contract.
     * @dev This call is used in the royalty registry contract.
     * @return coreAddress The address of the CHIZU core contract.
     */
    function getCHIZUCore() public view returns (address payable coreAddress) {
        return core;
    }

    function _setCore(address payable _core) internal {
        core = _core;
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[2000] private __gap;
}