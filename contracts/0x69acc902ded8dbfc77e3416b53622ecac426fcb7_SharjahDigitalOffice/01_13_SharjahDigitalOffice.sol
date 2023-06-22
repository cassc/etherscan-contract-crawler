// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SharjahDigitalOffice is Ownable, ERC721Enumerable {
    bool public transferAllowed;

    mapping(uint256 => string) public tokenURIs;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(
        address destinationAccount_,
        uint256 tokenId_,
        string calldata tokenURI_
    ) external onlyOwner {
        require(bytes(tokenURI_).length != 0, "SharjahDigitalOffice: URI should not be empty");

        _mint(destinationAccount_, tokenId_);

        tokenURIs[tokenId_] = tokenURI_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "SharjahDigitalOffice: URI query for nonexistent token");

        return tokenURIs[tokenId_];
    }

    function setTransferAllowed(bool transferAllowed_) external onlyOwner {
        transferAllowed = transferAllowed_;
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override {
        require(
            from_ == address(0) || to_ == address(0) || transferAllowed,
            "SharjahDigitalOffice: transfer is disabled"
        );

        super._beforeTokenTransfer(from_, to_, tokenId_);
    }
}