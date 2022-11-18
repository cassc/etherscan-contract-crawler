// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Monotonic.sol";

contract SimejiNFTLite is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Monotonic for Monotonic.Increaser;

    Monotonic.Increaser private _tokenIdCounter;

    string public _baseTokenUri;
    
    uint256 public _totalInventory;

    constructor(string memory name, string memory symbol, uint256 totalInventory) ERC721(name, symbol) {
        _totalInventory = totalInventory;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airdrop(address to, uint256 requested) external onlyOwner {
        safeMint(to, requested);
    }
    
    function safeMint(address to, uint256 requested) internal {
        uint256 tokenId = _tokenIdCounter.current();
        uint256 remain = _totalInventory - tokenId;
        require(remain > 0, "SimejiWorldCup2022 : quota exceeded");
        uint256 n = Math.min(remain, requested);

        for (uint256 i = 0; i < n; i++) {
            _safeMint(to, tokenId + i);
        }

        _tokenIdCounter.add(n);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenUri = baseTokenURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }
}