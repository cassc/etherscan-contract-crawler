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
import '../interfaces/IPancakeFactory.sol';

contract RouletteCasinoNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    address public rouletteContractAddr;
    address constant wbnbAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // testnet: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd, mainnet: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address constant pancakeFactoryAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73; // testnet: 0x6725F303b657a9451d8BA641348b6761A6CC7a17, mainnet: 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73

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
        require(maxBet > minBet, 'Min bet bigger than max bet');
        require(fee < 100, 'fee should be less than 100%');

        if (newTokenAddress != address(0)) {
            address BNB_Token_Pair = IPancakeFactory(pancakeFactoryAddr).getPair(newTokenAddress, wbnbAddr);
            require(BNB_Token_Pair != address(0));
        }

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