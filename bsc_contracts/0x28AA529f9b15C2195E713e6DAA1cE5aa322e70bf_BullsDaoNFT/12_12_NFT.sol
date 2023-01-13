// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BullsDaoNFT is ERC721, Ownable {
    uint256 public constant totalSupply = 1000;
    uint256 private _tokenIds = 1;

    string private _baseTokenURI;

    constructor () ERC721("BullsDao NFT", "BNFT") {
    }

    function mint(uint256 amount) public onlyOwner {
        require(_tokenIds + amount <= totalSupply + 1);

        for (uint i = 0; i < amount; i ++) {
            _mint(owner(), _tokenIds + i);
        }

        _tokenIds += amount;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}