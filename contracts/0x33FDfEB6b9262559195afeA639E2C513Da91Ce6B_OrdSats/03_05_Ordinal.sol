// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OrdSats is ERC721A, Ownable {
string _URI1 = "";
bool revealed = false;
    constructor() ERC721A("Ordinal Satoshis", "ORDSATS") {}


    function mint(address to,uint256 quant) external onlyOwner {
        _mint(to, quant);
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function changeURI(string memory uri) public onlyOwner {
        _URI1 = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _URI1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (revealed) {
           return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),'.json')) : '';
        }
        return bytes(baseURI).length != 0 ? baseURI : '';
    }
}