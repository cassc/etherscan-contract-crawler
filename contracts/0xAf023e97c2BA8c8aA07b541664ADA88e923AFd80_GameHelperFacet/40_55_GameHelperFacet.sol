//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./LibStorage.sol";
import {BookMainFacet} from "./BookMainFacet.sol";
import {GameInternalFacet} from "./GameInternalFacet.sol";
import {GameMainFacet} from "./GameMainFacet.sol";
import {GameChestFacet} from "./GameChestFacet.sol";

contract GameHelperFacet is WithStorage, GameInternalFacet {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct UserInfo {
        uint32 libraryUserSeedBlock;
        uint32 dailyChestUserSeedBlock;
        bool userInLibrary;
        uint16 regularKeyBalance;
        uint16 keyFragmentBalance;
        uint16 skeletonKeyBalance;
        uint16 diamondSkeletonKeyBalance;
        uint16 bookUpgradeBalance;
        uint16 bookNameTagBalance;
        Chest userActiveLibraryChest;
        bool libraryRandomnessSeedIsValid;
        bool dailyChestRandomnessSeedIsValid;
        uint userPrimaryPunkId;
        int userPrimaryPunkHealth;
        uint32[] userPrimaryPunkDamageEvents;
    }
    
    struct NFTVaultInfo {
        string slug;
        address[] allowedContracts;
        StoredNFT[] storedNFTs;
    }
    
    function getTokenInfo(string calldata slug) external view returns (GameItemTokenInfo memory) {
        return slugToTokenInfo(slug);
    }
    
    function getCurrentAuction() external pure returns (GameAuctionStorage memory) {
        return auct();
    }
    
    function getNFTVault(string memory slug) external view returns (NFTVaultInfo memory ret) {
        ret.slug = gs().nftVaults[slug].slug;
        ret.storedNFTs = gs().nftVaults[slug].storedNFTs;
        ret.allowedContracts = gs().nftVaults[slug].allowedContracts.toArray();
    }
    
    function getChest(string memory chestType) public view returns (Chest memory) {
        return gs().chests[chestType];
    }
    
    function getChestSet(string memory chestSet) public view returns (ChestSet memory) {
        return gs().chestSets[chestSet];
    }
    
    function getPrize(string memory slug) public view returns (Prize memory) {
        return gs().prizes[slug];
    }
    
    function getBalanceOfItem(address userAddress, string memory itemSlug) internal view returns (uint16) {
        GameMainFacet gameFacet = GameMainFacet(address(this));

        return uint16(gameFacet.balanceOf(userAddress, findIdBySlugOrRevert(itemSlug)));
    }
    
    function getUserInfo(address userAddress) external view returns (UserInfo memory) {
        BookMainFacet bookFacet = BookMainFacet(gs().bookContract);
        GameMainFacet gameFacet = GameMainFacet(address(this));
        
        uint userPrimaryPunkId = bookFacet.userToPrimaryPunkId(userAddress);
        
        return UserInfo({
            libraryUserSeedBlock: uint32(gs().userChestSetSeedBlocks[userAddress]["library"]),
            dailyChestUserSeedBlock: uint32(gs().userChestSetSeedBlocks[userAddress]["daily"]),
            userInLibrary: gs().userChestSetSeedBlocks[userAddress]["library"] > 1,
            regularKeyBalance: uint16(gameFacet.balanceOf(userAddress, findIdBySlugOrRevert("regular_key"))),
            keyFragmentBalance: uint16(gameFacet.balanceOf(userAddress, findIdBySlugOrRevert("key_fragment"))),
            skeletonKeyBalance: uint16(gameFacet.balanceOf(userAddress, findIdBySlugOrRevert("skeleton_key"))),
            diamondSkeletonKeyBalance: uint16(gameFacet.balanceOf(userAddress, findIdBySlugOrRevert("diamond_skeleton_key"))),
            
            bookUpgradeBalance: getBalanceOfItem(userAddress, "book_upgrade"),
            bookNameTagBalance: getBalanceOfItem(userAddress, "book_name_tag"),
            
            userActiveLibraryChest: getChest(gs().userChestSetActiveChestSlug[userAddress]["library"]),
            libraryRandomnessSeedIsValid: blockhash(gs().userChestSetSeedBlocks[userAddress]["library"]) > 0,
            dailyChestRandomnessSeedIsValid: blockhash(gs().userChestSetSeedBlocks[userAddress]["daily"]) > 0,
            userPrimaryPunkId: userPrimaryPunkId,
            userPrimaryPunkHealth: bookFacet.punkHealth(userPrimaryPunkId),
            userPrimaryPunkDamageEvents: bookFacet.getPunkDamageEvents(userPrimaryPunkId)
        });
    }
}