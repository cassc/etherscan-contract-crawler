// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";

import "./LibStorage.sol";

import {GameChestUtilsInternal} from "./GameChestUtilsInternal.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

contract GameChestFacetExt is ReentrancyGuard, GameChestUtilsInternal {
    using LibPRNG for LibPRNG.PRNG;

    function revealAndOpenChestSetChest(string calldata chestSetSlug) external nonReentrant {
        ChestSet storage chestSet = gs().chestSets[chestSetSlug];
        uint currentSeedBlock = gs().userChestSetSeedBlocks[msg.sender][chestSetSlug];
        
        LibPRNG.PRNG memory prng = getValidPRNGOrRevert(currentSeedBlock);
        
        Chest storage activeChest = weightedSelectChest(chestSet.chests, prng);
        
        PrizeWithProbability[] storage activeChestPrizes = activeChest.prizes;
        
        Prize storage prize;
        bool prizeSuccessfullyAwarded;
        
        do {
            prize = weightedSelectPrize(activeChestPrizes, prng);
            prizeSuccessfullyAwarded = awardPrizeToUser(prize, msg.sender, prng);
        } while (!prizeSuccessfullyAwarded);
        
        gs().userChestSetSeedBlocks[msg.sender][chestSetSlug] = 1;
        
        emit ChestRevealedAndOpened(msg.sender, chestSetSlug, activeChest.slug, prize.name);
    }
}