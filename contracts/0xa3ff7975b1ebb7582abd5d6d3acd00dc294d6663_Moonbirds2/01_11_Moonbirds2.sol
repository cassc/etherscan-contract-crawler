// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Moonbirds2 is ERC721, Ownable {
    constructor() ERC721("Moonbirds2", "MOONBIRD2") {
        mint(1);
    }

    string _baseTokenURI;
    mapping(address => uint256) _minted;
    uint256 public totalSupply = 0;

    // its free
    function mint(uint256 quantity) public {
        totalSupply += quantity;
        require(totalSupply <= 10000, "All Moonbirds2 minted");
        require(quantity <= 10, "Cant mint more than 10 Moonbirds2 in one tx");
        require(_minted[msg.sender] < 10, "Cant mint more than 10 Moonbirds2 per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
}