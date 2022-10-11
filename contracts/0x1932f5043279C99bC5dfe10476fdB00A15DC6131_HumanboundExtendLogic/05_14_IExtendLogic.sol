//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";

/**
 * @dev Interface for ExtendLogic extension
*/
interface IExtendLogic {
    /**
     * @dev Emitted when `extension` is successfully extended
     */
    event Extended(address extension);
    
    /**
     * @dev Emitted when extend() is called and contract owner has not been set
     */
    event OwnerInitialised(address newOwner);

    /**
     * @dev Extend function to extend your extendable contract with new logic
     *
     * Integrate with ExtendableStorage to persist state
     *
     * Sets the known implementor of each function of `extension` as the current call context
     * contract.
     *
     * Emits `Extended` event upon successful extending.
     *
     * Requirements:
     *  - `extension` contract must implement EIP-165.
     *  - `extension` must inherit IExtension
     *  - Must record the `extension` by both its interfaceId and address
     *  - The functions of `extension` must not already be extended by another attached extension
    */
    function extend(address extension) external;

    /**
     * @dev Returns a string-formatted representation of the full interface of the current
     *      Extendable contract as an interface named IExtended
     *
     * Expects `extension.getSolidityInterface` to return interface-compatible syntax with line-separated
     * function declarations including visibility, mutability and returns.
    */
    function getFullInterface() external view returns(string memory fullInterface);

    /**
     * @dev Returns an array of interfaceIds that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsInterfaceIds() external view returns(bytes4[] memory);
    /**
     * @dev Returns an array of function selectors that are currently implemented by the current
     *      Extendable contract
    */
    function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);

    /**
     * @dev Returns an array of all extension addresses that are currently attached to the
     *      current Extendable contract
    */
    function getExtensionAddresses() external view returns(address[] memory);
}

/**
 * @dev Abstract Extension for ExtendLogic
*/
abstract contract ExtendExtension is IExtendLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function extend(address extension) external;\n"
                "function getFullInterface() external view returns(string memory);\n"
                "function getExtensionsInterfaceIds() external view returns(bytes4[] memory);\n"
                "function getExtensionsFunctionSelectors() external view returns(bytes4[] memory);\n"
                "function getExtensionAddresses() external view returns(address[] memory);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](5);
        functions[0] = IExtendLogic.extend.selector;
        functions[1] = IExtendLogic.getFullInterface.selector;
        functions[2] = IExtendLogic.getExtensionsInterfaceIds.selector;
        functions[3] = IExtendLogic.getExtensionsFunctionSelectors.selector;
        functions[4] = IExtendLogic.getExtensionAddresses.selector;

        interfaces[0] = Interface(
            type(IExtendLogic).interfaceId,
            functions
        );
    }
}