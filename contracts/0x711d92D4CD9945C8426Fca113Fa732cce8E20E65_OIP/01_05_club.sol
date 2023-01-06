// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OIP is ERC721A, Ownable {

    string private _baseURIPrefix;

  
    constructor() ERC721A("Onchain Inspiration Pass", "OIP") {}

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function directMint(address _address, uint256 amount) public onlyOwner {

        _safeMint(_address, amount);
    }
}