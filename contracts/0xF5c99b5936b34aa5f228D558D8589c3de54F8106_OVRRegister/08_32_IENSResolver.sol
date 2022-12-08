pragma solidity ^0.8.14;

/**
 * @title EnsResolver
 * @dev Extract of the interface for ENS Resolver
 */
interface IENSResolver {
     /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node - The node to update.
     * @param addr - The address to set.
     */
    function setAddr(bytes32 node, address addr) external;

    /**
     * Returns the address associated with an ENS node.
     * @param node - The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address);
}