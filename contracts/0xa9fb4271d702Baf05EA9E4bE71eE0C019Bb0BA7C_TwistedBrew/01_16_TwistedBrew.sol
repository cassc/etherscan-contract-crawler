// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TwistedBrew is ERC721Enumerable, Pausable, Ownable 
{
    using Counters for Counters.Counter;
    address public drinkContactAddress = address(0);
    uint256 public cost = 0.030 ether;
    string public baseURI = "https://trippies.com/twisted-brew/metadata/";
    uint private maxSupply = 10021;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Twisted Brew", "BADBATCH")     
    {   
        _tokenIdCounter.increment();
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

    function setCost(uint256 newCost) public onlyOwner 
    {
        cost = newCost;
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

        for (uint i = 0; i < quantity; i++) 
        {
            uint256 tokenId = _tokenIdCounter.current();
            require (tokenId <= maxSupply, "Max quantity of NFT exceeded.");
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function burn(uint tokenId) external whenNotPaused
    {
        require(msg.sender == drinkContactAddress, "unauthorized to burn.");
        _burn(tokenId);
    }    
}