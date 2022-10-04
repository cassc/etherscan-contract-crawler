//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Interface {
    bytes4 interfaceId;
    bytes4[] functions;
}

/**
 * @dev Interface for Extension
*/
interface IExtension {
    /**
     * @dev Returns a full view of the functional interface of the extension
     *
     * Must return a list of the functions in the interface of your custom Extension
     * in the same format and syntax as in the interface itself as a string, 
     * escaped-newline separated.
     *
     * OPEN TO SUGGESTIONS FOR IMPROVEMENT ON THIS METHODOLOGY FOR 
     * DEEP DESCRIPTIVE RUNTIME INTROSPECTION
     *
     * Intent is to allow developers that want to integrate with an Extendable contract
     * that will have a constantly evolving interface, due to the nature of Extendables,
     * to be able to easily inspect and query for the current state of the interface and
     * integrate with it.
     *
     * See {ExtendLogic-getSolidityInterface} for an example.
    */
    function getSolidityInterface() external pure returns(string memory);

    /**
     * @dev Returns the interface IDs that are implemented by the Extension
     *
     * These are full interface IDs and ARE NOT function selectors. Full interface IDs are
     * XOR'd function selectors of an interface. For example the interface ID of the ERC721
     * interface is 0x80ac58cd determined by the XOR or all function selectors of the interface.
     * 
     * If an interface only consists of a single function, then the interface ID is identical
     * to that function selector.
     * 
     * Provides a simple abstraction from the developer for any custom Extension to 
     * be EIP-165 compliant out-of-the-box simply by implementing this function. 
     *
     * Excludes any functions either already described by other interface definitions
     * that are not developed on top of this backbone i.e. EIP-165, IExtension
    */
    function getInterface() external returns(Interface[] memory interfaces);
}