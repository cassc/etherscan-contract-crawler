// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// Local imports

import { ENSNamehash } from "./ENSNamehash.sol";

interface ENS {
    function resolver(bytes32 node) external view returns (Resolver);
    function owner(bytes32 node) external view returns (address);
}

interface Resolver {
    function addr(bytes32 node) external view returns (address);
}

/**
 * @dev The addresses below only work on Mainnet.
 */
contract ENSResolver {
    address internal constant _ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address internal constant _ENS_NAMEWRAPPER_ADDRESS = 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401;

    function ownerByName(string memory _name) public view virtual returns (address) {
        return ownerByNode(ENSNamehash.namehash(bytes(_name)));
    }

    function resolveByName(string memory _name) public view virtual returns (address) {
        return resolveByNode(ENSNamehash.namehash(bytes(_name)));
    }

    function ownerByNode(bytes32 _node) public view virtual returns (address) {
        ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        address _owner = ens.owner(_node);
        return _owner == _ENS_NAMEWRAPPER_ADDRESS ? ens.resolver(_node).addr(_node) : _owner;
    }

    function resolveByNode(bytes32 _node) public view virtual returns (address) {
        ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        return ens.resolver(_node).addr(_node);
    }
}