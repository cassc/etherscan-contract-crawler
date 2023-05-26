//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface ICCIPResolver {
    function text(bytes32 _node, string calldata _key) external view returns(string memory _value);
    function addr(bytes32 _node) external view returns(address _addr);
    function name(bytes32 node) external view returns (string memory);
}