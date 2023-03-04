// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAddrResolver} from "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";

contract ENSHelper is IERC165, IAddrResolver {
    string public ensName;

    bytes32 internal immutable ensNameHash;
    uint256 internal numberOfProxiesDeployed;
    mapping(bytes32 => address) public nodehashToAddress;

    constructor(string memory _ensName, bytes32 _ensNameHash) {
        ensNameHash = _ensNameHash;
        ensName = _ensName;
    }

    function registerDeployment(address _addr) internal returns (string memory reverseENSName) {
        numberOfProxiesDeployed += 1;

        string memory subdomain = Strings.toString(numberOfProxiesDeployed);
        reverseENSName = string.concat(subdomain, ".", ensName);

        bytes32 label = keccak256(abi.encodePacked(subdomain));
        bytes32 namehash = keccak256(abi.encodePacked(ensNameHash, label));
        nodehashToAddress[namehash] = _addr;

        ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e).setSubnodeRecord(
            ensNameHash,
            label,
            address(this),
            address(this),
            0
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAddrResolver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function addr(bytes32 node) public view virtual override returns (address payable) {
        return payable(nodehashToAddress[node]);
    }
}