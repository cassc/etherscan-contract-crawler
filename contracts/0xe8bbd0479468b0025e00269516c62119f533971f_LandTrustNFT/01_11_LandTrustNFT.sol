// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandTrustNFT is ERC1155Supply, Ownable {
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => address) public managers;

    constructor() ERC1155("") {}

    function setManager(address manager_, uint256 tokenId_) external onlyOwner {
        require(manager_ != address(0), "NFT: manager address should not be null");
        require(tokenId_ > 0, "NFT: tokenId should not be 0");
        require(managers[tokenId_] == address(0), "NFT: tokenId is already assigned");
        managers[tokenId_] = manager_;
    }

    modifier onlyManager(uint256 tokenId) {
        require(managers[tokenId] == msg.sender, "NFT: caller is not a manager");
        _;
    }

    modifier onlyManagerOrOwner(uint256 tokenId) {
        require(managers[tokenId] == msg.sender || owner() == _msgSender(), "NFT: caller is not the manager or owner");
        _;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function setURI(uint256 tokenId, string memory tokenURI) external onlyManagerOrOwner(tokenId) {
        tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    function mint(address account, uint256 tokenId, uint256 tokens) external onlyManager(tokenId) {
        _mint(account, tokenId, tokens, "");
    }

    function burn(address account, uint256 tokenId, uint256 tokens) external onlyManager(tokenId) {
        _burn(account, tokenId, tokens);
    }
}