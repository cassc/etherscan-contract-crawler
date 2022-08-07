// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ██▄ ▄▀▄ ▄▀▄ ▄▀  ██▀ █▀▄   ██▄ ██▀ █   █   ▀▄▀ ▄▀▀
// █▄█ ▀▄▀ ▀▄▀ ▀▄█ █▄▄ █▀▄   █▄█ █▄▄ █▄▄ █▄▄  █  ▄██

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract BoogerBellys is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint8 public constant maxMintAmount = 69;
    bool public paused = false;
    uint32 public constant maxCount = 10000;
    uint256 public constant cost = 0.05 ether;
    string public constant baseExtension = ".json";
    string public baseURI;
    Counters.Counter public _tokenIds;

    /** 
    Welcome to Booger Bellys!
    @param _name is the name of this collection
    @param _symbol is an abbreviation for this collection
    @param _initBaseURI is the IPFS link prefix that will be used to target all minted assets
    */ 
    constructor(string memory _name,
                string memory _symbol,
                string memory _initBaseURI) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        mint(6);
        pause(true);
    }
    
    /** 
    This is where the magic is.....
    Mints new Booger Belly! 
    @param _mintAmount is the amount of Booger Bellys minted
    */ 
    function mint(uint _mintAmount) public payable {
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Mint amount is not greater than 0");
        require(_mintAmount <= maxMintAmount, "Mint amount is greater than upper limit for minting");

        uint currentSupply = _tokenIds.current();
        require((currentSupply + _mintAmount) <= maxCount, "Current minted Boogers + requested Booger is larger than available supply");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Amount sent to contract is less than cost per Booger Belly");
        }

        uint256 newTokenId;
        for(uint i = 0; i < _mintAmount; i++) {
            _tokenIds.increment();
            newTokenId = _tokenIds.current();
            _safeMint(msg.sender, newTokenId);  
        }
    }

    /** 
    Returns an array of tokens owned by input address
    Empty array if no tokens are owned by specific address
    @param _owner is an address that is checked for BoogerBelly tokens
    */ 
    function getAllOwnerTokens(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    
    /** 
    Returns the IPFS link to the token image
    Emits error if the token does not exist (not yet minted)
    @param tokenId is the integer corresponding to the token ID
    */ 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
            : "";
    }

    /** 
    Sets the base URI (IPFS link) that will serve as prefix for each minted token 
    Exclusive to contract owner
    @param _newBaseURI is IPFS link string that will be used at each mint
    */ 
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    /** 
    Function to pause or unpause new minting on the contract
    Previously minted tokens will be unaffected
    Exclusive to contract owner
    @param _state is a boolean value that will enable/disable minting 
    */ 
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    /** 
    Function to withdraw ETH from contract
    Exclusive to contract owner
    */ 
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}