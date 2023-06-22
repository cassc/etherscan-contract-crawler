// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElectricVisions is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 5000;

    string private baseURI;

    constructor() ERC721A("Electric-Visions", "EV")  {}

    function mint(uint256 quantity) external onlyOwner {
        require((totalSupply() + quantity) <= MAX_SUPPLY, "Minting would exceed max supply.");
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * To change the starting tokenId: 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}