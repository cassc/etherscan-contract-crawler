// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CellBlocks is ERC721A, Ownable {

    uint256 public maxSupply = 555;
    uint256 public maxPerTxn = 3;
    uint256 public cost = 0.005 ether;

    string public baseURI = "ipfs://QmTmNMnS4Xs7Rgnk5GAgrKpTH6h1BUCZe7RRCpyQiYSGcC/";

    constructor() ERC721A("Cell Blocks", "BLOCK") {}

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function mint(uint256 _amount) public payable {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");
        require(_amount <= maxPerTxn, "exceeds max token amount");
        require(msg.value >= _amount * cost, "not enough ether");

        _safeMint(msg.sender, _amount);
    }

    function devMint(uint256 _amount) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "exceeds max supply");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}