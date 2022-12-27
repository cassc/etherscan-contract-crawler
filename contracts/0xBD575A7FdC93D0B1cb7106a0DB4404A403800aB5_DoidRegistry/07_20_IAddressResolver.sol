// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint256 coinType, bytes newAddress);

    struct TypedAddress {
        uint256 coinType;
        bytes addr;
    }

    /**
     * @dev Make a messge to sign for setting address.
     * @param name name to set address.
     * @param coinType type of coin to set address.
     * @param a address to set.
     * @param timestamp signature will expire after 24 hours since timestamp.
     * @param nonce nonce.
     * @return message to sign.
     */
    function makeAddrMessage(
        string memory name,
        uint256 coinType,
        address a,
        uint256 timestamp,
        uint256 nonce
    ) external returns (string memory);

    /**
     * @dev Set address for name with coinType.
     * @param name name to set address.
     * @param coinType type of coin to set address.
     * @param a address to set.
     * @param timestamp signature will expire after 24 hours since timestamp.
     * @param nonce nonce.
     * @param signature signature of makeAddrMessage.
     */
    function setAddr(
        string memory name,
        uint256 coinType,
        address a,
        uint256 timestamp,
        uint256 nonce,
        bytes memory signature
    ) external;

    /**
     * @dev returns address for coinType of a node
     * @param node request node.
     * @param coinType coinType to request.
     * @return address in bytes.
     */
    function addrOfType(bytes32 node, uint256 coinType) external view returns (bytes memory);

    /**
     * Returns the address associated with the node.
     * @param node The node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address);

    /**
     * @dev returns all address bytes for all cointypes for a node
     * @param node request node.
     * @return TypedAddress array of all addresses with type.
     */
    function addrs(bytes32 node) external view returns (TypedAddress[] memory);
}