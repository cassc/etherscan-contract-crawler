// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BaseResolver.sol";

abstract contract AddrResolver is BaseResolver {
    bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 private constant ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint private constant COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32 => mapping(uint => bytes)) _addresses;

    /**
     * Sets the address associated with an KEY3 node.
     * May only be called by the owner of that node in the KEY3 registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, _addressToBytes(a));
    }

    /**
     * Returns the address associated with an KEY3 node.
     * @param node The KEY3 node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(address(0));
        }
        return _bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint coinType,
        bytes memory a
    ) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, _bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType)
        public
        view
        returns (bytes memory)
    {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == ADDR_INTERFACE_ID ||
            interfaceId == ADDRESS_INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }
}