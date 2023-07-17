// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
// Total number of packs that will be airdroped to investors/influencers
uint256 constant TOTAL_NUM_PACKS_AIRDROP = 200;
// Total number of packs that can be minted
uint256 constant TOTAL_NUM_PACKS_VIP = 800;
// Total number of packs that can minted publicly
uint256 constant TOTAL_NUM_PACKS = 1500 + TOTAL_NUM_PACKS_VIP + TOTAL_NUM_PACKS_AIRDROP;
// Number of cards in each pack
uint32 constant NUM_CARDS_IN_PACK = 4;
// Max tokens an address in the allowlist can mint
uint256 constant MAX_PER_LIST_MINTER = 2;
// Price per each token in wei
uint256 constant MINT_PRICE = 60000000000000000;
// Total number of cards that can be minter
uint256 constant TOTAL_NUM_CARDS = TOTAL_NUM_PACKS * NUM_CARDS_IN_PACK;