// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMerkle {
    function verify(bytes32 leaf, bytes32[] memory proof) external view returns (bool);
    function leaf(address user) external pure returns (bytes32);
    function isPermitted(address account, bytes32[] memory proof) external view returns (bool);
    function setRoot(bytes32 _root) external;
}