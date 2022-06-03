// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract FilthyMerica is ERC721Enumerable, Ownable {  
    using Address for address;
    using Strings for uint256;
    
    // Starting and stopping sale and presale
    bool public saleActive = false;

    // Price of each token
    uint256 public price = 0.09 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 1776;

    uint256 public constant MAX_PER_ADDRESS_PUBLIC = 4;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    string public baseExtension = ".json";
    bool public revealed = false;
    string public notRevealedUri;

    // Team addresses for withdrawals   
    address public Treasury = 0x80bd15B854384B9E8b920f56A3aE2687c1368a65;

    constructor () ERC721 ("Filthy Merica", "FM") {
        setBaseURI("ipfs://QmdF2hGXyLp6zZPKkXY7iNGcFN534NDrtGPGdmCFy1xEi6/");
        setNotRevealedURI("ipfs://QmdwuH3oxTNcCo3s6NA765zxroDpszsTMSizJHppLnDBCW/Hidden.json");
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // mint function
    function mint(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        
        if (saleActive) {
            require( _amount > 0 && _amount <= MAX_PER_ADDRESS_PUBLIC,    "Can only mint between 1 and 4 tokens at once" );
            require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
            require(balanceOf(msg.sender) + _amount <= MAX_PER_ADDRESS_PUBLIC, "Can only mint up to 4 tokens per wallet");
            require( msg.value == price * _amount,   "Wrong amount of ETH sent" );
            for(uint256 i; i < _amount; i++){
                _safeMint( msg.sender, supply + i + 1); // Token id starts from 1
            }
        } else {
            require( saleActive,                     "Sale isn't active" );
        }
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId)public view  virtual override returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");        
        if(revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }
    
    // withdraw all amount from contract
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no balance to withdraw");
        _widthdraw(Treasury, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}