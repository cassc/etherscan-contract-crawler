// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ACircle is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 51;

    constructor() ERC721A("Abstract Circle", "ACRL") {
        _safeMint(msg.sender, 1);
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint(uint256 quantity) external payable {
        require((price * quantity) <= msg.value, "Not enough amount sent.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed max supply.");
        _safeMint(msg.sender, quantity);
    }
}