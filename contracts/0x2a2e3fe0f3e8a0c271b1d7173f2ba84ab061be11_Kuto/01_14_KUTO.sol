// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Kuto is ERC721, Ownable, ERC721Enumerable, ReentrancyGuard {

    using Strings for uint256;
    
    string public baseURI;
    uint256 public maxMint = 7777;
    uint256 public currMint = 1000;
    uint256 public cost = 0.1 ether;
    bool public paused = false;

    mapping(uint256 => string) private _tokenURIs;
      
    address private creatorAddress;

    constructor() ERC721("Kuto's Many Lives", "KUTO") {
        setBaseURI("https://ipfs.moralis.io:2053/ipfs/QmQh9xQm9w4atfb3LCLgJjabgY8TTz9oQNzzMKeDanoQqR/metadata/");
        creatorAddress = msg.sender;
        paused = false;
        uint16[22] memory reserveToken = [366, 79, 73, 749, 600, 135, 210, 460, 667, 756, 834, 913, 432, 616, 518, 23, 473, 505, 914, 901, 345, 137];
        for(uint256 i=0;i<reserveToken.length;i++){
            _safeMint(msg.sender, uint256(reserveToken[i]));
            _tokenURIs[reserveToken[i]] = string(abi.encodePacked(_baseURI(), Strings.toString(reserveToken[i]), ".json"));
        }
    }

     // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
  
    function mint(uint256 _tokenId) public payable {
        require(!_exists(_tokenId),"token already minted");
        require(paused==false, "sale closed");
        require(_tokenId<=maxMint, "maximum token passed");
        require(_tokenId<=currMint && _tokenId>0, "invalid _tokenId");
        require(msg.value >= cost, "minimum price required");
        require(payable(creatorAddress).send(msg.value));
        _safeMint(msg.sender, _tokenId);
        _tokenURIs[_tokenId] = string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
    }

    function mintByOwner(address[] memory _tos, uint256[] memory _tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tos.length; i++) {
            require(_tokenIds[i]<=maxMint, "maximum token passed");
            require(!_exists(_tokenIds[i]),"token already minted");
            _safeMint(_tos[i], _tokenIds[i]);
            _tokenURIs[_tokenIds[i]] = string(abi.encodePacked(_baseURI(), Strings.toString(_tokenIds[i]), ".json"));
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
    returns (string memory)
    {
        require(
          _exists(_tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );

        if(bytes(_tokenURIs[_tokenId]).length>0){
            return _tokenURIs[_tokenId];
        }

        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    //only owner
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function setcurrMint(uint256 _currMint) public onlyOwner {
        require(_currMint<=maxMint, "maximum token passed");
        require(_currMint>currMint,"new mint size must be greater");
        currMint = _currMint;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}