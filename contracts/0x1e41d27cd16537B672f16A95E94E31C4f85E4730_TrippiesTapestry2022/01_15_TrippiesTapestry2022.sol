// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrippiesTapestry2022 is ERC721Enumerable, Pausable, Ownable 
{
    uint256 public cost = 0.05 ether;
    uint256 private constant MAX = 180;
    string public baseURI = "https://trippies.com/tapestry-2022/metadata/";

    constructor() ERC721("Trippies Tapestry 2022", "TRPTAP")     
    {        
        pause();
    }

    function contractURI() public view returns (string memory) 
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "";    
    }

    function setCost(uint256 newCost) public onlyOwner 
    {
        cost = newCost;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function mint(address to, uint quantity) public whenNotPaused payable
    {
        require(msg.sender == owner() || msg.value >= cost * quantity);
        require(totalSupply() + quantity <= MAX);

        for (uint i = 0; i < quantity; i++) 
        {
            uint256 newTokenId = totalSupply() + 1; 
            _safeMint(to, newTokenId);
        }
    }

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}