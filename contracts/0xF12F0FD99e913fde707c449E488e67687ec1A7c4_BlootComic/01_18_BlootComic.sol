// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@pixelvault/contracts/PVERC721.sol";
import "@pixelvault/contracts/PVAllowlist.sol";

/*
* @author Niftydude
*/
contract BlootComic is PVERC721, PVAllowlist {
    uint256 public windowOpens;
    uint256 public windowCloses;

    bytes32 public merkleRoot;
    mapping(address => uint256) public purchased;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _windowOpens,
        uint256 _windowCloses,
        bytes32 _merkleRoot
    ) PVERC721(_name, _symbol, _uri) {
        windowOpens = _windowOpens;
        windowCloses = _windowCloses;

        merkleRoot = _merkleRoot;
    }                  

    function editMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyOwner {
        merkleRoot = _merkleRoot;
    }     

    function editWindows(
        uint256 _windowOpens, 
        uint256 _windowCloses
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }      

    function mint(
        uint256 amount,
        uint256 index,
        uint256 maxAmount,
        bytes32[] calldata merkleProof
    ) external whenInAllowlist(index, maxAmount, merkleProof, merkleRoot) {
        require (block.timestamp > windowOpens && block.timestamp < windowCloses, "Window closed");
        require(purchased[msg.sender] + amount <= maxAmount, "max purchase amount exceeded");      
        require(amount > 0 && amount <= 40, "amount not allowed");  

        purchased[msg.sender] += amount;

        _mintMany(msg.sender, amount);
    }       

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }             
}