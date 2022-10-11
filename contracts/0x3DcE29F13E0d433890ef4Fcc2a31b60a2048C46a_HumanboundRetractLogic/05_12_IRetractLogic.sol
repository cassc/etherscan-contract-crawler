//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Extension.sol";
import {ExtendableState, ExtendableStorage} from "../../storage/ExtendableStorage.sol";

/**
 * @dev Interface for RetractLogic extension
*/
interface IRetractLogic {
    /**
     * @dev Emitted when `extension` is successfully removed
     */
    event Retracted(address extension);

    /**
     * @dev Removes an extension from your Extendable contract
     *
     * Requirements:
     * - `extension` must be an attached extension
    */
    function retract(address extension) external;
}

abstract contract RetractExtension is IRetractLogic, Extension {
    /**
     * @dev see {IExtension-getSolidityInterface}
    */
    function getSolidityInterface() override virtual public pure returns(string memory) {
        return  "function retract(address extension) external;\n";
    }

    /**
     * @dev see {IExtension-getImplementedInterfaces}
    */
    function getInterface() override virtual public pure returns(Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](1);
        functions[0] = IRetractLogic.retract.selector;

        interfaces[0] = Interface(
            type(IRetractLogic).interfaceId,
            functions
        );
    }
}