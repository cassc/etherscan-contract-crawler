// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/IAddressResolver.sol";

abstract contract AddressResolver is IAddressResolver, ResolverBase {
    uint256 private constant COIN_TYPE_ETH = 60;

    mapping(bytes32 => mapping(uint256 => bytes)) _addresses;

    function setAddr(bytes32 node, address a)
        external
        authorized(node)
    {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    function addr(bytes32 node)
        public
        view
        override
        returns (address)
    {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public authorized(node) {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint256 coinType)
        public
        view
        override
        returns (bytes memory)
    {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b)
        internal
        pure
        returns (address a)
    {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    uint256[49] private __gap;
}