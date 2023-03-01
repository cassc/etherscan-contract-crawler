// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
using Strings for uint256;

contract TrippiesComic is Ownable, ERC1155Supply 
{
    uint256 public cost = 0.02 ether;
    mapping(uint => bool) private tokenAvailability;
    string public baseURI = "https://trippies.com/comics/metadata/";

    constructor() ERC1155("") 
    {
    }

    function contractURI() public view returns (string memory) 
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "";    
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) 
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setTokenAvailability(uint256 id, bool isAvailable) public onlyOwner
    {
        tokenAvailability[id] = isAvailable;
    }

    function getTokenAvailability(uint256 id) public view returns (bool)
    {
        return tokenAvailability[id];
    }

    function setCost(uint256 newCost) public onlyOwner 
    {
        cost = newCost;
    }

    function mint(address account, uint256 id, uint256 amount)
        public        
        payable
    {
        require(tokenAvailability[id] == true, "token is not available to mint");
        require(msg.sender == owner() || msg.value >= cost * amount, "cost not met");
        _mint(account, id, amount, "");        
    }

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}