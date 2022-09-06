// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MetaBloxNFT is ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable
{
    using Counters for Counters.Counter;
    using Address for address;

    string private _baseURI1;
    string private _baseURI2;
    uint256 public divNum = 50;
    uint256 public constant MAX_SUPPLY = 1000;
    Counters.Counter private _totalMinted;

    constructor(
        string memory baseURI1_,
        string memory baseURI2_
    ) ERC721("MetaBloxNFT", "MetaBlox") {
        _baseURI1 = baseURI1_;
        _baseURI2 = baseURI2_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMintBatch(address to, uint256 amount) public onlyOwner {
        require(
            _totalMinted.current() + amount <= MAX_SUPPLY,
            "MetaBloxNFT: minting exceeds MAX_SUPPLY"
        );
        for (uint256 i = 1; i <= amount; i++) {
            _totalMinted.increment();
            _safeMint(to, _totalMinted.current());
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function changeBaseURI(string memory newBaseURI1, string memory newBaseURI2) external onlyOwner
    {
        _baseURI1 = newBaseURI1;
        _baseURI2 = newBaseURI2;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        require(_exists(tokenId), "MetaBloxNFT: token ID not exists");
        if (tokenId <= divNum) {
            return _baseURI1;
        }
        return _baseURI2;
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

}