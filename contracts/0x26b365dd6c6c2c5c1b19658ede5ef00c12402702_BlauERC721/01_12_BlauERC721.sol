// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlauERC721 is ERC721, Ownable {
    string private _base;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _base = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _base;
    }

    /**
     * @notice Change the base url for all NFTs
     */
    function setBaseURI(string calldata base) external onlyOwner {
        _base = base;
    }

    /**
     * @notice Mint multiple NFTs
     * @param to address that new NFTs will belong to
     * @param tokenIds ids of new NFTs to create
     * @param preApprove optional account that is pre-approved to move tokens
     *                   after token creation.
     */
    function massMint(
        address to,
        uint256[] calldata tokenIds,
        address preApprove
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
            if (preApprove != address(0)) {
                _approve(preApprove, tokenIds[i]);
            }
        }
    }

    /**
     * @notice Mint a single nft
     */
    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }
}