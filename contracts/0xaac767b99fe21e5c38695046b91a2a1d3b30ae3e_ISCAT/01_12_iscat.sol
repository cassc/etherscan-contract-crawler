// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

/**
 * @title ISCAT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation, Use ERC721A for batch mint
 */
contract ISCAT is ERC721A, Ownable {
    uint256 public immutable MAX_CATS;
    string public baseTokenURI;
    uint256 public maxBatchSize;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 batchSize) ERC721A(name, symbol) {
        MAX_CATS = maxNftSupply;
        maxBatchSize = batchSize;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setBatchSize(uint256 batchSize) external onlyOwner {
        maxBatchSize = batchSize;
    }

    function mints(uint numberOfTokens, address to) public onlyOwner {
        uint256 total = totalSupply() + numberOfTokens;
        require(total <= MAX_CATS, "would exceed max supply of Cats");
        require((numberOfTokens % maxBatchSize == 0 || numberOfTokens < maxBatchSize),"can only mint a multiple of the maxBatchSize");
        if (numberOfTokens < maxBatchSize) {
            _safeMint(to, numberOfTokens);
        } else {
            uint256 numChunks = numberOfTokens / maxBatchSize;
            for (uint256 i = 0; i < numChunks; i++) {
                _safeMint(to, maxBatchSize);
            }
        }

    }
}