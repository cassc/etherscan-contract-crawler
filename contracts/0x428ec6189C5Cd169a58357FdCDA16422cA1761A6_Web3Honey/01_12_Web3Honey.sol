// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Web3Honey is ERC721,  Ownable {
    constructor()ERC721("web3honey POF", "HONEY"){
      _tokenCount = 0;
      _metadataTypes = 12;
      _baseTokenUri = "https://web3honey.infura-ipfs.io/ipfs/QmXqGi5qo5LYEWyq98JYX9Ua3uizESN1oYH4EhUL6FQXju/";
    }

    uint256 _tokenCount;
    uint32 private _metadataTypes;
    string private _baseTokenUri;

    mapping(address => bool) isMinted;
    mapping(uint256 => string) idToNumber;

    function mint() public {
        require(!isMinted[msg.sender], "You cannot mint twice");
        uint random = uint(keccak256(abi.encodePacked(_tokenCount, msg.sender, "Web3Honey")));
        string memory n = Strings.toString(random % _metadataTypes + 1);
        idToNumber[_tokenCount] = n;
        _safeMint(msg.sender, _tokenCount);
        isMinted[msg.sender] = true;
        ++_tokenCount;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721)returns(string memory){
      bytes memory uri = abi.encodePacked(_baseTokenUri, idToNumber[tokenId]);
      return string(uri);
    }

    function setMetadataTypes(uint32 number) public onlyOwner {
      _metadataTypes = number;
    }

    function setBaseTokenUri(string memory  uri) public onlyOwner {
      _baseTokenUri = uri;
    }

    function baseTokenURI()
      public view returns(string memory) {
      return _baseTokenUri;
    }

    function getMetadataTypes()
      public view returns(uint) {
      return _metadataTypes;
    }
}