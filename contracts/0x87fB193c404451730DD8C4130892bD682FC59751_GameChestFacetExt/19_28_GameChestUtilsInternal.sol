// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/LibSort.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SafeCastLib.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LibStorage.sol";

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {ERC1155DInternal} from "./ERC1155D/ERC1155DInternal.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";

contract GameChestUtilsInternal is ReentrancyGuard, WithStorage, ERC1155DInternal, GameInternalFacet  {
    using LibPRNG for LibPRNG.PRNG;
    
    error ChestSetHasNoActiveChest(string chestSetSlug);
    error NoChestRevealNeeded(string chestSetSlug);
    error WeightedSelectSlugFailed(string[] slugs, uint[] probabilities);
    error BlockhashOutOfRange(uint requestedBlock, uint currentBlock, int diff);
    
    event ChestOpened(address indexed user, Prize prize);
    event ChestRevealedAndOpened(
        address indexed user,
        string chestSetSlug,
        string chestSlug,
        string prizeName
    );
    event ChestSetChestRevealed(address indexed user, string chestSetSlug, string chestSlug);
    
    // Need to parse events client-side
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    function weightedSelectPrize(
        PrizeWithProbability[] storage prizesWithProbabilities,
        LibPRNG.PRNG memory prng
    ) internal view returns (Prize storage) {
        uint total;
        
        for (uint i; i < prizesWithProbabilities.length; i++) {
            total += prizesWithProbabilities[i].probability;
        }
        
        uint rand = prng.uniform(total);
        
        uint current;
        
        for (uint i; i < prizesWithProbabilities.length; i++) {
            current +=  prizesWithProbabilities[i].probability;
            if (rand < current) {
                return gs().prizes[prizesWithProbabilities[i].prizeSlug];
            }
        }
        
        revert("WeightedSelectPrizesFailed");
    }
    
    function weightedSelectChest(
        ChestWithProbability[] storage chestsWithProbabilities,
        LibPRNG.PRNG memory prng
    ) internal view returns (Chest storage) {
        uint total;
        
        for (uint i; i < chestsWithProbabilities.length; ++i) {
            total += chestsWithProbabilities[i].probability;
        }
        
        uint rand = prng.uniform(total);
        
        uint current;
        
        for (uint i; i < chestsWithProbabilities.length; ++i) {
            current +=  chestsWithProbabilities[i].probability;
            if (rand < current) {
                return gs().chests[chestsWithProbabilities[i].chestSlug];
            }
        }
        
        revert("WeightedSelectChestsFailed");
    }
    
    function sendRandomNFTsFromVaultsUsingSeed(address to, string memory slug, uint256 amount, uint256 seed) internal returns (bool) {
        NFTVault storage vault = gs().nftVaults[slug];
        
        if (amount > vault.storedNFTs.length) return false;
        
        LibPRNG.PRNG memory prng = LibPRNG.PRNG(seed);
        
        for (uint i; i < amount; ++i) {
            uint randomIndex = prng.uniform(vault.storedNFTs.length);
            StoredNFT memory nft = vault.storedNFTs[randomIndex];
            
            IERC721(nft.contractAddress).transferFrom(address(this), to, nft.tokenId);
            
            uint lastIndex = vault.storedNFTs.length - 1;
            
            if (lastIndex != randomIndex) {
                StoredNFT memory lastValue = vault.storedNFTs[lastIndex];
                vault.storedNFTs[randomIndex] = lastValue;
            }
            
            vault.storedNFTs.pop();
        }
        
        return true;
    }
    
    function awardPrizeToUser(Prize memory prize, address user, LibPRNG.PRNG memory prng) internal nonReentrant returns (bool allPrizesAwarded) {
        if (prize.gameItemAmount > 0) {
            _mint(user, findIdBySlugOrRevert(prize.gameItemSlug), prize.gameItemAmount, "");
            allPrizesAwarded = true;
        }
        
        if (prize.NFTAmount > 0) {
            allPrizesAwarded = sendRandomNFTsFromVaultsUsingSeed(user, prize.vaultSlug, prize.NFTAmount, prng.next());
        }
    }
    
    function getValidPRNGOrRevert(uint seedBlock) internal view returns (LibPRNG.PRNG memory) {
        bytes32 seed = blockhash(seedBlock);
        
        if (seed == bytes32(0)) {
            revert BlockhashOutOfRange({
                requestedBlock: seedBlock,
                currentBlock: block.number,
                diff: int(block.number) - int(seedBlock)
            });
        }
        
        uint combinedSeed = uint(keccak256(abi.encodePacked(seed, msg.sender)));
                
        return LibPRNG.PRNG(combinedSeed);
    }
}