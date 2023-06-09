// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nonfungiballs is ERC721A, Ownable {
    string private _baseURIextended;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721A("Nonfungiballs", "BALLS") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

     function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint")
        ;require(msg.sender == tx.origin, "Humans Only Coomer(<:")
        ;require(numberOfTokens <= 10, "Can only mint 10 tokens at a time")
        ;require(_totalMinted() + numberOfTokens <= 6969, "Purchase would exceed max supply")
        ;_safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}