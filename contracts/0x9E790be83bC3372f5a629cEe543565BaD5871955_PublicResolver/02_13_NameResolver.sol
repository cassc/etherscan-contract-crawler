// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(bytes32 => string) names;

    function setName(bytes32 node, string calldata newName)
        external
        virtual
        authorized(node)
    {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    function name(bytes32 node)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(INameResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    uint256[49] private __gap;
}