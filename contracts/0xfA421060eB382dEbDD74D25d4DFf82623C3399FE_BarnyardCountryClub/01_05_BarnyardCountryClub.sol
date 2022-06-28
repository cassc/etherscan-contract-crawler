// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BarnyardCountryClub is ERC721A, Ownable {
    string private _baseURIextended;
    bool public saleIsActive = false;

    constructor(string memory baseURI) ERC721A("BarnyardCountryClub", "BCC") {
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
        uint256 total = _totalMinted()
        ;require(saleIsActive, "Sale must be active to mint")
        ;require(msg.sender == tx.origin, "Humans Only (<:")
        ;require(numberOfTokens <= 10, "Can only mint 10 tokens at a time")
        ;require(total + numberOfTokens <= 10000, "Purchase would exceed max supply")
        ;if(total + numberOfTokens > 1001){
            require(0.08 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }
        _mint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}