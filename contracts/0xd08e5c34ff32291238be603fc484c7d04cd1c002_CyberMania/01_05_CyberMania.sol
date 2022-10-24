// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberMania is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 10010;

    constructor() ERC721A("CyberMania", "CYBERMANIA") {}

    function initMint(uint256 quantity) public onlyOwner {
        require(quantity > 0, 'must be greater than 0');
        require(totalSupply() + quantity <= MAX_SUPPLY, 'exceeds the max supply');
        _mint(msg.sender, quantity);
    }

    string public baseURI = "https://storage.googleapis.com/cybermania/";

    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://storage.googleapis.com/cybermania/opensea.json";
    }

}