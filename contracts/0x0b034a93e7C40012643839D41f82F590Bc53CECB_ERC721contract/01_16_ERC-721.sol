// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract ERC721contract is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    uint256 public Mint_Price = .009 ether;
    uint256 public Max_Supply = 999;
    string _baseTokenURI;


    constructor(string memory baseURI) ERC721("SamurAI", "SAI") {
        //Start Token ID @ 1//
        _tokenIdCounter.increment();
        _pause();
        _baseTokenURI = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(uint numberOfTokens) public payable{
        require(totalSupply() < Max_Supply, "Not enough tokens left");
        require(Mint_Price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct.");
        require(totalSupply().add(numberOfTokens) <= Max_Supply, "Purchase would exceed max supply of tokens.");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            if (totalSupply() < Max_Supply) {
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
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

    function withdraw() public onlyOwner() {
        require(address(this).balance > 0, "Balance is Zero");
        payable(owner()).transfer(address(this).balance);
    }

}