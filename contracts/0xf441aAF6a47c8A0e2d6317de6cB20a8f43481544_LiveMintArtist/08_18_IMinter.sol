// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IMinter 
{ 
    function purchase(uint256 _projectId) payable external returns (uint tokenID); 
    function purchaseTo(address _to, uint _projectId) payable external returns (uint tokenID);
    function purchaseTo(address _to) payable external returns (uint tokenID);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}