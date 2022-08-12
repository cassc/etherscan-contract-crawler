// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BowieBadger is ERC721A, Ownable {
    
    string public baseURI;
    string public constant BASE_EXTENSION = ".json";
    uint256 public maxSupply;

    mapping(address => bool) public addresses;

    constructor() ERC721A("BowieBadger", "BADGER") {}

    function mint(address _address) public onlyOwner {
        require(!addresses[_address], "Address has already minted");
        require(totalSupply() + 1 <= maxSupply, "Mint would exceed max supply of tokens.");
        addresses[_address] = true;
        _safeMint(_address, 1); 
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(_id), BASE_EXTENSION))
            : "";
    }

}