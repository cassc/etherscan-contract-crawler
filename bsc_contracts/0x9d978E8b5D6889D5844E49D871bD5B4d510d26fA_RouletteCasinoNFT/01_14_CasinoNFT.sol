/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../interfaces/IRoulette.sol';

contract RouletteCasinoNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    address rouletteContractAddr;

    constructor() ERC721('BNBPotRoulette', 'BNBPotRoulette') {}

    event Mint(uint256 tokenId);

    /**
     * @dev mint Casino NFTS
     *
     * @param tokenURI metadata url for NFT
     * @param newTokenAddress token address that will be used in the casino
     */
    function mint(
        string memory tokenURI,
        address newTokenAddress,
        string calldata tokenName,
        uint256 maxBet,
        uint256 minBet,
        uint256 fee
    ) external onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        IRoulettePot(rouletteContractAddr).addCasino(newItemId, newTokenAddress, tokenName, maxBet, minBet, fee);
        emit Mint(newItemId);
    }

    function setRouletteContractAddress(address addr) external onlyOwner {
        rouletteContractAddr = addr;
    }
}