// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartContract is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    uint256 public cost = 0.03 ether; 
    uint256 public maxSupply = 8000;
    uint256 public maxMintAmount = 10; 
    bool public presale = true;
    bool public paused = true;
    mapping (address => bool) private whitelist;
    
    constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }
    
    // internal function
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI; // we created a func in case we'll need to change the base URI
    }
    
    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Sale is paused");
        require(_mintAmount > 0, "Mint amount must be positive");
        require(_mintAmount <= maxMintAmount, "Mint amount more than maximum");
        require(supply + _mintAmount <= maxSupply, "Minting past max supply is not possible");
        
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Insufficient value"); // if a minter is not a SC owner he will be charged
            if (presale) {
                require(whitelist[_to], "You need to be whitelisted");
            }
        }
        
        for (uint256 i = 1; i <= _mintAmount; i++) { // uint256 i = 1 cause we want our token id to start from 1
            _safeMint(_to, supply + i); // supply + i - current token id for a current minter; address and tokenId should be passed
        }
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner); // returns number of tokens owned
        uint256[] memory tokenIds = new uint256[](ownerTokenCount); // initialize an array of tokenIds with the length = ownerTokenCount
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i); // return an array of the tokenIds owned by a minter
        }
        return tokenIds;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){ // this func returns metadata in right format
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token"); // check if the tocken with this tokenId exists
        string memory currentBaseURI = _baseURI(); // from base ORI func - see above
        return string(abi.encodePacked(currentBaseURI, tokenId.toString()));
    } // a string with a full file name will be returned
    
    // only owner functions
    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }
    
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setPresale(bool _presale) public onlyOwner {
        presale = _presale;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            delete whitelist[addresses[i]];
        }
    }
    
}