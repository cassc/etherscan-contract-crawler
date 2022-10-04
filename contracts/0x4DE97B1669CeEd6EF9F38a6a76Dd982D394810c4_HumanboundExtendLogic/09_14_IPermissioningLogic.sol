//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";

/**
 * @dev Interface for PermissioningLogic extension
*/
interface IPermissioningLogic {
    /**
     * @dev Emitted when `owner` is updated in any way
     */
    event OwnerUpdated(address newOwner);

    /**
     * @dev Initialises the `owner` of the contract as `msg.sender`
     *
     * Requirements:
     * - `owner` cannot already be assigned
    */
    function init() external;

    /**
     * @notice Updates the `owner` to `newOwner`
    */
    function updateOwner(address newOwner) external;

    /**
     * @notice Give up ownership of the contract.
     * Proceed with extreme caution as this action is irreversible!!
     *
     * Requirements:
     * - can only be called by the current `owner`
    */
    function renounceOwnership() external;

    /**
     * @notice Returns the current `owner`
    */
    function getOwner() external view returns(address);
}

/**
 * @dev Abstract Extension for PermissioningLogic
*/
abstract contract PermissioningExtension is IPermissioningLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function init() external;\n"
                "function updateOwner(address newOwner) external;\n"
                "function renounceOwnership() external;\n"
                "function getOwner() external view returns(address);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override virtual public returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](4);
        functions[0] = IPermissioningLogic.init.selector;
        functions[1] = IPermissioningLogic.updateOwner.selector;
        functions[2] = IPermissioningLogic.renounceOwnership.selector;
        functions[3] = IPermissioningLogic.getOwner.selector;

        interfaces[0] = Interface(
            type(IPermissioningLogic).interfaceId,
            functions
        );
    }
}