// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "tiny-erc721/contracts/TinyERC721.sol";

import "./TokenSale.sol";

contract TBDVoyagerBowls is TinyERC721, ERC2981, Ownable, TokenSale {
    uint256 public maxSupply = 1000;
    string private baseURI;

    // third constructor argument is maximum batch size, 0 for no limit
    constructor() TinyERC721("Voyager Bowls", "VOYB", 0) {}

    function cutSupply() external onlyOwner {
        maxSupply = totalSupply();
    }

    function setRoyalty(address receiver, uint96 value) external onlyOwner {
        _setDefaultRoyalty(receiver, value);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _guardMint(address, uint256 quantity)
        internal
        view
        virtual
        override
    {
        unchecked {
            require(tx.origin == msg.sender, "Can't mint from contract");
            require(
                totalSupply() + quantity <= maxSupply,
                "Exceeds max supply"
            );
        }
    }

    function _mintTokens(address to, uint256 quantity)
        internal
        virtual
        override
    {
        _mint(to, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(TinyERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw(address receiver) external onlyOwner {
        (bool success, ) = receiver.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}