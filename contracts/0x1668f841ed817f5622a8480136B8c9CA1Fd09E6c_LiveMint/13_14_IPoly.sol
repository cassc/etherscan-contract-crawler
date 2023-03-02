// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IPoly 
{ 
    // without delegate.cash
    function purchaseTo(
        address _to, 
        uint _projectId, 
        address _ownedNFTAddress, 
        uint _ownedNFTTokenID
    ) payable external returns (uint tokenID);
}