// SPDX-License-Identifier: MIT
/**
 * @title IMinter Minter Interface
 * @author @brougkr
 */
pragma solidity ^0.8.19;
interface IMinter 
{ 
    function purchase(uint256 _projectId) payable external returns (uint tokenID); // Custom
    function purchaseTo(address _to, uint _projectId) payable external returns (uint tokenID); // ArtBlocks Standard Minter
    function purchaseTo(address _to) external returns (uint tokenID); // Custom
    function purchaseTo(address _to, uint _projectId, address _ownedNFTAddress, uint _ownedNFTTokenID) payable external returns (uint tokenID); // ArtBlocks PolyMinter
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function _MintToFactory(uint ProjectID, address To, uint Amount) external; // MintPassFactory
    function _MintToFactory(address To, uint Amount) external; // MintPassBespoke
}