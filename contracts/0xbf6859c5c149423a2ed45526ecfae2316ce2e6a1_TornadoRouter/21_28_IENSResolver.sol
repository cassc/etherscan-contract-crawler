// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// Local imports

interface IENSResolver {
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function addr(bytes32 node) external view returns (address);
    function contenthash(bytes32 node) external view returns (bytes memory);
}