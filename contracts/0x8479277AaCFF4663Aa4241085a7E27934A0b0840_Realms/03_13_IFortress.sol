//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFortress {
    function getFortress(bytes32 _fortressHash) external view returns (bytes16 name, address owner, int256 x, int256 y, uint256 wins);
    function transferFortress(bytes32 _fortressHash, address _newOwner) external;
}