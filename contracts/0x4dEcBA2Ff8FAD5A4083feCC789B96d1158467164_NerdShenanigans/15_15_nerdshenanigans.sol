//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NerdShenanigans is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    string  public baseURI;
    string BertsNote = "You don't see anything here";
    
    Counters.Counter private _tokenIds;
    
    constructor() ERC721("Nerd Shenanigans", "NNS") {
    }

    //takes a list of addresses and airdrops the NFTs to the target
    function handOutItems(address[] calldata wAddresses) public onlyOwner {

        for (uint i = 0; i < wAddresses.length; i++) {
            _mintSingleNFT(wAddresses[i]);
        }
    }
    
    function _mintSingleNFT(address wAddress) private {
        uint newTokenID = _tokenIds.current();
        _safeMint(wAddress, newTokenID);
        _tokenIds.increment();
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));
    }

    function writeNoteOnBack(string memory s) public onlyOwner {
        BertsNote = s;
    } 

    function checkTheBack(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return BertsNote;
    }

}