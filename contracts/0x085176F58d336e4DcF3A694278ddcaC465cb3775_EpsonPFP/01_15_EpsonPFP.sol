// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract EpsonPFP is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    event SetBaseURI(string indexed baseURI);

    constructor(string memory baseURI) ERC721('EpsonPFP', 'EPFP') {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;

        emit SetBaseURI(baseURI);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function batchSafeMint(address to, uint256 batchSize) public onlyOwner {
        uint256 i;
        for (i = 0; i < batchSize; i++) {
            safeMint(to);
        }
    }

    function safeAirdrop(address[] memory recipients, uint256[] memory batchSizes) public onlyOwner {
        require(recipients.length == batchSizes.length, 'EpsonPFP: recipients and batchSizes length mismatch');

        uint256 i;
        for (i = 0; i < recipients.length; i++) {
            batchSafeMint(recipients[i], batchSizes[i]);
        }
    }
}