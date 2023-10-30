// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollectionPartnerInterface{
    function ownerOf(uint256 _token) public view returns(address){}
    function walletOfOwner(address _owner) public view returns(uint256[] memory){}
}