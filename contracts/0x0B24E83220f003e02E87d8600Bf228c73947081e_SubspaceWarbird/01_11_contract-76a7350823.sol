// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract SubspaceWarbird is ERC721A, ERC721ABurnable, ERC2981, Ownable {
    uint256 private startTokenId = 1;
    string public baseURI;
    uint256 public mintPrice = 0.001 ether;
    bool public mintIsActive = false;
    uint public maxSupply = 10;
    uint public maxQuantity = 1;
    uint96 royaltyFeesInBips = 1000;

    constructor(string memory baseURI_, bool mintIsActive_) ERC721A("Subspace - Warbird", "WARBIRD") {
        baseURI = baseURI_;
        mintIsActive = mintIsActive_;
        _setDefaultRoyalty(msg.sender, royaltyFeesInBips);
    }

    /* Overrides */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view override returns (uint256) {
        return startTokenId;
    }

    /* Owner */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setMintIsActive(bool mintIsActive_) external onlyOwner {
        mintIsActive = mintIsActive_;
    }

    function setMaxSupply(uint maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMaxQuantity(uint maxQuantity_) external onlyOwner {
        maxQuantity = maxQuantity_;
    }

    function setRoyalty(address royaltyAddress, uint96 royaltyFeesInBips_) external onlyOwner {
        _setDefaultRoyalty(royaltyAddress, royaltyFeesInBips_);
    }

    function withdraw() external payable onlyOwner {
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    /* General */
    function contractURI() public view returns (string memory) {
        return string.concat(_baseURI(), "contract");
    }

    function mint() external payable {
        require(msg.value == mintPrice, "Not enough ETH sent");
        require(totalSupply() < maxSupply, "No more available");
        _mint(msg.sender, maxQuantity);
    }

    /* Declare interfaces */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}