//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IENSAdmin {
    function setAddr(bytes32 node, uint256 coinType, bytes  memory a) external;
    function setAddr(bytes32 node, address a) external;
    function setDNSRecords(bytes32 node, bytes memory data) external;
    function setText(bytes32 node, string memory key, string memory value) external;

}