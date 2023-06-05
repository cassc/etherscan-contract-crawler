// SPDX-License-Identifier: MIT
//
// The China NFT
// thechinanft.com
// #IYKYK  NFT holders of The China NFT and Metropolis get airdrops.
// 10% The China Team, 10% CEX listing & Community, 20% NFT holders, 60% LP Locked Forever
// NFT holder snapshot for airdrop on July 10th 2023
// https://opensea.io/collection/the-china-nft-v1
// https://opensea.io/collection/metropolis-888

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TheChina is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("TheChina", "CN") ERC20Permit("TheChina") {
        _mint(msg.sender, 88888888 * 10 ** decimals());
    }
}