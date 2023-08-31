// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IENSResolver {
    function setContenthash(bytes32 node, bytes memory hash) external;

    function setAddr(bytes32 node, address a) external;

    function addr(bytes32 node) external view returns (address);

    function contenthash(bytes32 node) external returns (bytes memory);
}