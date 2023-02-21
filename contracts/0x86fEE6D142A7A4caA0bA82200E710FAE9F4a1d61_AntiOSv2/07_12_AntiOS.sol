// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./Blur/DefaultOperatorFilterer.sol";

contract AntiOSv2 is ERC721A, ERC2981, Ownable, DefaultOperatorFilterer {
    uint256 public immutable MAX_SUPPLY = 1000;
    string private _baseTokenUri = "ipfs://QmSYHNqjLSe8UPQaPGCXnqn2aBqtbZNsgiyTFbpkVKixmW/";

    constructor() ERC721A("AntiOSv2", "AO") {
        _setDefaultRoyalty(msg.sender, 0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function setBaseUri(string memory newUri) external onlyOwner {
        _baseTokenUri = newUri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        return _baseTokenUri;
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Cannot mint any more");
        _mint(owner(), quantity);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}