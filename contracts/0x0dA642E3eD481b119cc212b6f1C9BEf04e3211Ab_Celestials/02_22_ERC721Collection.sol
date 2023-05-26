// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../token/ERC721/ERC721A.sol";
import "../token/ERC721/extensions/ERC721ABurnable.sol";
import "../token/ERC721/extensions/ERC721AOwnersExplicit.sol";


contract ERC721Collection is Ownable, ERC721A, ERC721ABurnable, ERC721AOwnersExplicit {
    using SafeMath for uint256;

    uint256 public maxSupply = 5555;
    string private _URI;

    constructor(string memory name, string memory symbol) 
        ERC721A(name, symbol) {}

    function setMaxSupply(uint256 supply) public onlyOwner {
        require(supply > 0, "NotPositive");
        maxSupply = supply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _URI;
    }

    function setBaseURI(string memory URI) public onlyOwner {
        _URI = URI;
    }

    function mintOwner(address to, uint256 quantity) public onlyOwner {
        require(totalSupply().add(quantity) <= maxSupply, "PurchaseExeedsMaxSupply");
        _safeMint(to, quantity);
    }

    function mint(address to, uint256 quantity) internal {
        require(totalSupply().add(quantity) <= maxSupply, "PurchaseExeedsMaxSupply");
        _safeMint(to, quantity);
    }

    
}