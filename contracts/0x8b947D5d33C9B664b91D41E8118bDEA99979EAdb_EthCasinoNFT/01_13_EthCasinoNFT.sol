/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract EthCasinoNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    constructor() ERC721('RoulettePot', 'RoulettePot') {}

    event Mint(uint256 tokenId);

    /**
     * @dev mint Casino NFTS
     *
     * @param tokenURI metadata url for NFT
     */
    function mint(string memory tokenURI) external onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit Mint(newItemId);
    }
}