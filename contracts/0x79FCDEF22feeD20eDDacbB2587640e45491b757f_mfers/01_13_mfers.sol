// SPDX-License-Identifier: MIT

/*
              __                     
 _ __ ___    / _|   ___   _ __   ___ 
| '_ ` _ \  | |_   / _ \ | '__| / __|
| | | | | | |  _| |  __/ | |    \__ \
|_| |_| |_| |_|    \___| |_|    |___/
                                     
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract mfers is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    constructor(address payable shareholderAddress_) ERC721("mfer", "MFER") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 150; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= 10, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= 10021, "Purchase would exceed max supply of tokens");
        require(0.069 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 10021) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }
}