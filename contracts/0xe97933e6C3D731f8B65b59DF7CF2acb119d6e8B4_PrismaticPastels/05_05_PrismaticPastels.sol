// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PrismaticPastels is ERC721A, Ownable {

    uint256 public maxSupply = 777;
    uint256 public maxFree = 1;
    uint256 public maxPerTxn = 9;
    uint256 public cost = 0.009 ether;

    string public baseURI = "ipfs://QmXwLyDDF2EF3QLzo75RsVkcMKqUDtfxvDqbEfoHT97eWN/";

    mapping(address => bool) public freeMinted;

    constructor() ERC721A("Prismatic Pastels", "PRISM") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function mintFree() public {
        require(totalSupply() + 1 <= maxSupply, "exceeds max supply");
        require(freeMinted[msg.sender] == false, "exceeds max free per wallet");

        freeMinted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintPaid(uint256 _amount) public payable {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");
        require(_amount <= maxPerTxn, "exceeds max token amount");
        require(msg.value >= _amount * cost, "not enough ether");

        _safeMint(msg.sender, _amount);
    }

    function devMint(uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");

        _safeMint(msg.sender, _amount);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}