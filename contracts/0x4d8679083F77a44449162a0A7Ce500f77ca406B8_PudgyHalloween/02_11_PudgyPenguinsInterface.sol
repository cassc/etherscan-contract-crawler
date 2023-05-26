// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PudgyPenguinsInterface{
    function ownerOf(uint256 _token) public view returns(address){}
    function walletOfOwner(address _owner) external view returns (uint256[] memory){}
}