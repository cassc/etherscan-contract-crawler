// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract StudioBySVNTMIN is ERC721URIStorage, Ownable {
    uint256 private _tokenId;

    constructor() ERC721("SVNT_MIN Special Edition","SVNTMIN") {}

    function airdrop(address to, string calldata _tokenURI) external onlyOwner {
        _mint(to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        ++_tokenId;
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }
}