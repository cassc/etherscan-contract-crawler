// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TwistedTrippies is ERC721Enumerable, Ownable 
{
    address public drinkContactAddress = address(0);
    string public baseURI = "https://trippies.com/twisted-trippies/metadata/";
    uint private maxSupply = 10021;

    constructor() ERC721("Twisted Trippies", "TWISTEDTRIPPIES")     
    {   
    }

    function withdraw() public onlyOwner 
    {   
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function contractURI() public view returns (string memory) 
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "contract.json")) : "";    
    }

    function setDrinkContract(address a) public onlyOwner 
    {
        drinkContactAddress = a;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function mint(address to, uint tokenId) public 
    {
        require (msg.sender == drinkContactAddress, "drink contract only");
        require (tokenId >= 1, "Invalid token id.");
        require (tokenId <= maxSupply, "Max quantity of NFT exceeded.");
        _safeMint(to, tokenId);
    }  
}