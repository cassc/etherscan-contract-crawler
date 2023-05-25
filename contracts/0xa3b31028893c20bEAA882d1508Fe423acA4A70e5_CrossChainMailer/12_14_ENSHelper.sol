pragma solidity ^0.8.16;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ENS} from "ens-contracts/registry/ENS.sol";
import {IAddrResolver} from "ens-contracts/resolvers/profiles/IAddrResolver.sol";
import {INameResolver} from "ens-contracts/resolvers/profiles/INameResolver.sol";

contract ENSHelper {
    using Address for address;
    using ENSNamehash for bytes;

    // Same address for Mainet, Ropsten, Rinkerby, Gorli and other networks;
    address constant ensRegistryAddr = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    /// The namehash of the `eth` TLD in the ENS registry, eg. namehash("eth").
    bytes32 public constant ETH_NODE = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));

    /// @notice Returns the ENS name for a given address, or an string address if no name is set.
    /// @param _addr The address to lookup.
    /// @return name The ENS name for the given address.
    /// @dev For this to successfully retrieve a name, the address must have the reverse record
    ///     set, and the forward record must match the address.
    function getName(address _addr) public view returns (string memory name) {
        if (!ensRegistryAddr.isContract()) {
            return Strings.toHexString(_addr);
        }

        // Use reverse resolver to get the ENS name that address this has.
        bytes32 nodeReverse = reverseNode(_addr);
        address reverseResolverAddr = ENS(ensRegistryAddr).resolver(nodeReverse);
        if (reverseResolverAddr == address(0) || !reverseResolverAddr.isContract()) {
            return Strings.toHexString(_addr);
        }

        name = INameResolver(reverseResolverAddr).name(nodeReverse);
        if (bytes(name).length == 0) {
            return Strings.toHexString(_addr);
        }

        // ENS does not enforce the accuracy of reverse records, so you you must always perform a
        // forward resolution for the returned name and check it matches the original address.
        bytes32 nodeForward = bytes(name).namehash(0);
        address forwardResolverAddr = ENS(ensRegistryAddr).resolver(nodeForward);
        if (forwardResolverAddr == address(0) || !forwardResolverAddr.isContract()) {
            return Strings.toHexString(_addr);
        }

        address forwardAddr = IAddrResolver(forwardResolverAddr).addr(nodeForward);
        if (forwardAddr == _addr) {
            return name;
        } else {
            return Strings.toHexString(_addr);
        }
    }

    // Below are helper functions from ReverseRecords.sol, used so it's not necassary to maintain
    // a reference to the contract on each chain.
    // Source: https://github.com/ensdomains/reverse-records/blob/6ef80ba0a445b3f7cdff7819aaad1efbd8ad22fb/contracts/ReverseRecords.sol

    /// @notice This is the equivalant of namehash('addr.reverse')
    bytes32 public constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    /// @notice Returns the node hash for a given account's reverse records.
    function reverseNode(address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(_addr)));
    }

    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) {} {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }
}

/// @dev Source: https://github.com/JonahGroendal/ens-namehash/blob/d956b0be0ae5d14191067ed398c4454e35f4558d/contracts/ENSNamehash.sol
library ENSNamehash {
    function namehash(bytes memory domain) internal pure returns (bytes32) {
        return namehash(domain, 0);
    }

    function namehash(bytes memory domain, uint256 i) internal pure returns (bytes32) {
        if (domain.length <= i) {
            return 0x0000000000000000000000000000000000000000000000000000000000000000;
        }

        uint256 len = LabelLength(domain, i);

        return keccak256(abi.encodePacked(namehash(domain, i + len + 1), keccak(domain, i, len)));
    }

    function LabelLength(bytes memory domain, uint256 i) private pure returns (uint256) {
        uint256 len;
        while (i + len != domain.length && domain[i + len] != 0x2e) {
            len++;
        }
        return len;
    }

    function keccak(bytes memory data, uint256 offset, uint256 len) private pure returns (bytes32 ret) {
        require(offset + len <= data.length);
        assembly {
            ret := keccak256(add(add(data, 32), offset), len)
        }
    }
}