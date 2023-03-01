//SPDX-License-Identifier: Unlicense
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

import {BookMainFacet} from "./BookMainFacet.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

contract GameChestFacet is UsingDiamondOwner, WithStorage, ERC1155DInternal, GameInternalFacet, ReentrancyGuard {
    error WeightedSelectSlugFailed(string[] slugs, uint[] probabilities);
    error NotEnoughBookHealth(int health, int cost);
    error NoPrimaryBook();
    error IncorrectNumberOfNFTsDeposited(uint deposited, uint required);
    error NoChestRevealNeeded(string chestSetSlug);
    error ArrayLengthMismatch();
    error BlockhashOutOfRange(uint requestedBlock, uint currentBlock, int diff);
    error SlugCannotBeBlank();
    error NFTNotAllowedInRequestedVault(string vaultSlug, address nftContract);
    error NeedToDepositAtLeastOneNFT(string slug, address[] nftContracts, uint256[][] tokenIds);
    error ChestSetHasNoActiveChest(string chestSetSlug);
    
    using LibString for *;
    using SafeCastLib for *;
    using LibSort for *;
    using LibPRNG for LibPRNG.PRNG;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    event ChestOpened(address indexed user, Prize prize);
    event ChestSetPricePaid(address indexed user, string chestSetSlug, address[] nftContracts, uint256[][] tokenIds);
    event ChestSetChestRevealed(address indexed user, string chestSetSlug, string chestSlug);
    
    // Need to parse events client-side
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    function updatePrize(
        string calldata slug,
        string calldata name,
        string calldata vaultSlug,
        uint NFTAmount,
        string calldata gameItemSlug,
        uint gameItemAmount
    ) external onlyRole(ADMIN) {
        require(bytes(slug).length > 0, "Slug required");
        require(bytes(name).length > 0, "Name required");
        
        Prize storage prize = gs().prizes[slug];
        
        prize.slug = slug;
        prize.name = name;
        
        if (bytes(vaultSlug).length > 0) {
            NFTVault storage vault = gs().nftVaults[vaultSlug];
            require(vault.slug.eq(vaultSlug), "Vault must exist");
            
            prize.vaultSlug = vaultSlug;
            prize.NFTAmount = NFTAmount;
        }
        
        if (bytes(gameItemSlug).length > 0) {
            GameItemTokenInfo storage tokenInfo = slugToTokenInfo(gameItemSlug);
            require(tokenInfo.slug.eq(gameItemSlug), "Game Item must exist");
            
            prize.gameItemSlug = gameItemSlug;
            prize.gameItemAmount = gameItemAmount;
        }
    }
    
    function updateNFTVault(string calldata slug, address[] calldata allowedContracts) external onlyRole(ADMIN) {
        if (bytes(slug).length == 0) revert SlugCannotBeBlank();
        
        NFTVault storage vault = gs().nftVaults[slug];
        
        vault.slug = slug;
        
        for (uint i; i < vault.allowedContracts.length(); i++) {
            vault.allowedContracts.remove(vault.allowedContracts.at(i));
        }
        
        for (uint i; i < allowedContracts.length; i++) {
            vault.allowedContracts.add(allowedContracts[i]);
        }
    }
    
    function updateChestSet(
        string calldata chestSetSlug,
        ChestWithProbability[] calldata chestsWithProbabilities,
        ChestSetCost calldata cost
    ) external onlyRole(ADMIN) {
        if (bytes(chestSetSlug).length == 0) revert SlugCannotBeBlank();
        
        ChestSet storage chestSet = gs().chestSets[chestSetSlug];
        
        chestSet.slug = chestSetSlug;
        
        chestSet.cost = cost;
        
        delete chestSet.chests;
        
        for (uint i = 0; i < chestsWithProbabilities.length; i++) {
            chestSet.chests.push(chestsWithProbabilities[i]);
        }
    }
    
    function updateChest(
        string calldata chestSlug,
        string calldata name,
        PrizeWithProbability[] calldata chestPrizes
    ) external onlyRole(ADMIN) {
        require(bytes(chestSlug).length > 0);
        
        Chest storage chest = gs().chests[chestSlug];
        
        chest.slug = chestSlug;
        chest.name = name;
        delete chest.prizes;
        
        for (uint i = 0; i < chestPrizes.length; i++) {
            chest.prizes.push(chestPrizes[i]);
        }
    }
    
    function updateSeedBlockGap(uint8 _seedBlockGap) external onlyRole(ADMIN) {
        gs().seedBlockGap = _seedBlockGap;
    }

    function weightedSelectSlug(
        string[] memory slugs,
        uint[] memory probabilities,
        LibPRNG.PRNG memory prng
    ) internal pure returns (string memory) {
        uint total;
        
        for (uint i; i < slugs.length; i++) {
            total += probabilities[i];
        }
        
        uint rand = prng.uniform(total);
        
        uint current;
        
        for (uint i; i < slugs.length; i++) {
            current += probabilities[i];
            if (rand < current) {
                return slugs[i];
            }
        }
        
        revert WeightedSelectSlugFailed({
            slugs: slugs,
            probabilities: probabilities
        });
    }
    
    function payChestSetPrice(
        string calldata chestSetSlug,
        address[] calldata nftContracts,
        uint256[][] calldata tokenIds
    ) external {
        BookMainFacet bookFacet = BookMainFacet(gs().bookContract);

        ChestSet storage chestSet = gs().chestSets[chestSetSlug];
        
        if (chestSet.cost.bookHealthCost > 0) {
            uint userPrimaryPunkId = bookFacet.userToPrimaryPunkId(msg.sender);
            if (userPrimaryPunkId == 0) revert NoPrimaryBook();
            
            for (uint i; i < chestSet.cost.bookHealthCost; ++i) {
                bookFacet.makePunkTakeDamageRevertIfAlreadyDead(userPrimaryPunkId);
            }
        }
        
        if (chestSet.cost.gameItemAmount > 0) {
            _burn(
                msg.sender,
                slugToTokenId(chestSet.cost.gameItemSlug),
                chestSet.cost.gameItemAmount
            );
        }
        
        if (chestSet.cost.NFTAmount > 0) {
            uint totalNFTsStored = depositNFTsToVaultInternal(
                chestSet.cost.vaultSlug,
                nftContracts,
                tokenIds,
                msg.sender
            );
            
            if (totalNFTsStored != chestSet.cost.NFTAmount) {
                revert IncorrectNumberOfNFTsDeposited({deposited: totalNFTsStored, required: chestSet.cost.NFTAmount});
            }
        }
        
        gs().userChestSetSeedBlocks[msg.sender][chestSetSlug] = block.number + 1;
        
        emit ChestSetPricePaid({user: msg.sender, chestSetSlug: chestSetSlug,
        nftContracts: nftContracts, tokenIds: tokenIds});
    }
    
    function revealChestSetChest(string calldata chestSetSlug) external {
        ChestSet storage chestSet = gs().chestSets[chestSetSlug];
        
        if (chestSet.chests.length == 1) revert NoChestRevealNeeded({chestSetSlug: chestSetSlug});
        
        string[] memory slugs = new string[](chestSet.chests.length);
        uint[] memory probabilities = new uint[](chestSet.chests.length);
        
        for (uint i; i < chestSet.chests.length; i++) {
            slugs[i] = chestSet.chests[i].chestSlug;
            probabilities[i] = chestSet.chests[i].probability;
        }
        
        uint currentSeedBlock = gs().userChestSetSeedBlocks[msg.sender][chestSetSlug];
        LibPRNG.PRNG memory prng = getValidPRNGOrRevert(currentSeedBlock);
        
        string memory activeSlug = weightedSelectSlug(slugs, probabilities, prng);
        
        gs().userChestSetActiveChestSlug[msg.sender][chestSetSlug] = activeSlug;
        
        emit ChestSetChestRevealed({user: msg.sender, chestSetSlug: chestSetSlug, chestSlug: activeSlug});
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
    
    // TODO permissions
    // function _adminDepositNFTsToVault(string memory vaultSlug, address nftContract, uint tokenId) external {
    //     require(block.chainid != 1);
        
    //     IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    //     gs().nftVaults[vaultSlug].storedNFTs.push(StoredNFT(false, nftContract, tokenId.toUint88()));
    // }
    
    function adminDepositNFTsToVault(
        string calldata slug,
        address[] calldata nftContracts,
        uint256[][] calldata tokenIds
    ) external onlyRoleStr("nft_admin") {
        if (nftContracts.length != tokenIds.length) revert ArrayLengthMismatch();
        
        NFTVault storage vault = gs().nftVaults[slug];
        
        for (uint i; i < nftContracts.length; ++i) {
            address currentContract = nftContracts[i];
            uint[] memory currentTokenIds = tokenIds[i];
            
            vault.allowedContracts.add(currentContract);
            
            transferTokensAndStoreInVault(vault, msg.sender, currentTokenIds, currentContract);
        }
    }
    
    function adminWithdrawNFTsFromVault(string calldata slug, uint amount) external onlyRole(ADMIN) {
        sendRandomNFTsFromVaultsUsingSeed(msg.sender, slug, amount, 1);
    }
    
    function transferTokensAndStoreInVault(NFTVault storage vault, address from,
    uint[] memory tokenIds, address nftContract) internal {
        for (uint j; j < tokenIds.length; ++j) {
            uint currentTokenId = tokenIds[j];
            
            IERC721(nftContract).transferFrom(from, address(this), currentTokenId);
            vault.storedNFTs.push(StoredNFT(false, nftContract, currentTokenId.toUint88()));
        }
    }
    
    function depositNFTsToVaultInternal(string memory slug, address[] memory nftContracts, uint256[][] memory tokenIds, address from) internal returns (uint totalNFTsStored) {
        if (nftContracts.length == 0 || tokenIds[0].length == 0) {
            revert NeedToDepositAtLeastOneNFT({
                slug: slug,
                nftContracts: nftContracts,
                tokenIds: tokenIds
            });
        }
        
        if (nftContracts.length != tokenIds.length) revert ArrayLengthMismatch();
        
        NFTVault storage vault = gs().nftVaults[slug];
        
        for (uint256 i = 0; i < nftContracts.length; i++) {
            address currentContract = nftContracts[i];
            uint256[] memory currentTokenIds = tokenIds[i];
            
            if (!vault.allowedContracts.contains(currentContract)) {
                revert NFTNotAllowedInRequestedVault({
                    vaultSlug: slug,
                    nftContract: currentContract
                });
            }
            
            totalNFTsStored += currentTokenIds.length;
            transferTokensAndStoreInVault(vault, from, currentTokenIds, currentContract);
        }
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
    
    function openChestSetChest(string calldata chestSetSlug) external nonReentrant {
        ChestSet storage chestSet = gs().chestSets[chestSetSlug];
        
        Chest storage activeChest;
        
        if (chestSet.chests.length > 1) {
            activeChest = gs().chests[gs().userChestSetActiveChestSlug[msg.sender][chestSetSlug]];
            if (bytes(activeChest.slug).length == 0) revert ChestSetHasNoActiveChest({chestSetSlug: chestSetSlug});
        } else {
            activeChest = gs().chests[chestSet.chests[0].chestSlug];
        }
        
        string[] memory slugs = new string[](activeChest.prizes.length);
        uint[] memory probabilities = new uint[](activeChest.prizes.length);
        
        for (uint i; i < activeChest.prizes.length; i++) {
            slugs[i] = activeChest.prizes[i].prizeSlug;
            probabilities[i] = activeChest.prizes[i].probability;
        }
        
        uint currentSeedBlock = gs().userChestSetSeedBlocks[msg.sender][chestSetSlug];
        LibPRNG.PRNG memory prng = getValidPRNGOrRevert(currentSeedBlock);
        
        bool prizeSuccessfullyAwarded;
        Prize memory prize;
        
        while (!prizeSuccessfullyAwarded) {
            string memory prizeSlug = weightedSelectSlug(slugs, probabilities, prng);
            prize = gs().prizes[prizeSlug];
        
            prizeSuccessfullyAwarded = awardPrizeToUser(prize, msg.sender, prng);
        }
        
        gs().userChestSetSeedBlocks[msg.sender][chestSetSlug] = 1;
        delete gs().userChestSetActiveChestSlug[msg.sender][chestSetSlug];
        
        emit ChestOpened(msg.sender, prize);
    }
    
    function awardPrizeToUser(Prize memory prize, address user, LibPRNG.PRNG memory prng) internal returns (bool allPrizesAwarded) {
        if (prize.gameItemAmount > 0) {
            _mint(user, findIdBySlugOrRevert(prize.gameItemSlug), prize.gameItemAmount, "");
            allPrizesAwarded = true;
        }
        
        if (prize.NFTAmount > 0) {
            allPrizesAwarded = sendRandomNFTsFromVaultsUsingSeed(user, prize.vaultSlug, prize.NFTAmount, prng.next());
        }
    }
}