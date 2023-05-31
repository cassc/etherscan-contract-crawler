// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPublicResolver {
    function setAddr(bytes32 _node, address _address) external;

    function addr(bytes32 _node) external view returns (address);

    function setText(
        bytes32 _node,
        string calldata _key,
        string calldata _value
    ) external;

    function text(bytes32 _node, string calldata _key)
        external
        view
        returns (string memory);
}