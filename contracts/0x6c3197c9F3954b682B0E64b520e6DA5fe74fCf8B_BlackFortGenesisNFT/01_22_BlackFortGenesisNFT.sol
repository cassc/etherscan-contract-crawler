//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./rarible/ERC721RaribleRoyalty.sol";


contract BlackFortGenesisNFT is ERC721RaribleRoyalty, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 constant MAX_SUPPLY = 501;
    uint256 constant PRICE = 1.1 ether;
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(string(abi.encodePacked(_baseTokenURI, tokenId.toString())), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721RaribleRoyalty, ERC721Enumerable) returns (bool) {
        return ERC721RaribleRoyalty.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function mint(uint256 amountOfTokens) external payable returns (bool) {
        require(amountOfTokens * PRICE == msg.value, "BlackFortGenesisNFT: wrong amount sent");

        uint256 refund = 0;
        if (totalSupply() + amountOfTokens > MAX_SUPPLY) {
            refund = totalSupply() + amountOfTokens - MAX_SUPPLY;
            amountOfTokens = MAX_SUPPLY - totalSupply();
        }

        for (uint256 i = 0; i < amountOfTokens; i++) {
            _safeMint(msg.sender, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }

        if (refund != 0) {
            (bool result,) = msg.sender.call{value:(refund * PRICE)}("");
            return result;
        }
        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        (bool result,) = msg.sender.call{value:address(this).balance}("");
        return result;
    }

    function setBaseTokenURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setDefaultRoyalties(LibPart.Part[] memory royalties) public onlyOwner {
        _setDefaultRoyalties(royalties);
    }

    function setTokenRoyalties(uint256 tokenId, LibPart.Part[] memory royalties) public onlyOwner {
        _setTokenRoyalties(tokenId, royalties);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}