// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibStorage.sol";
import "hardhat/console.sol";

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";

import { ERC721DInternal } from "./ERC721D/ERC721DInternal.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import {BookInternalFacet} from "./BookInternalFacet.sol";
import {ERC2981} from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";

import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";

contract BookInitFacet is WithStorage, UsingDiamondOwner, BookInternalFacet, OperatorFilterer, ERC721DInternal {
    using EnumerableSet for EnumerableSet.UintSet;
    
    function init() external {
        if (bk().initialized) return;
        
        _setName("Babylon Book");
        _setSymbol("BB");

        bk().nameSingular = "Babylon Book";
        
        bk().externalLink = "https://babylon.game";
        
        bk().tokenDescription = "One of the millions of books available at the Babylon library";
        
        bk().isMintActive = true;
        
        bk().maxNameRuneCount = 50;
        bk().damangeEventsLastForDuration = 1 weeks;
        bk().startingPunkHealth = 3;
        
        bk().imageScaleUpFactor = block.chainid == 31337 ? 1 : 35;
        
        if (block.chainid != 1) testMint();
        
        _initBookData();
        initRoles();
        initOperatorFilter();
        
        ds().supportedInterfaces[type(IERC165).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds().supportedInterfaces[type(IERC173).interfaceId] = true;
        
        ds().supportedInterfaces[type(IERC721).interfaceId] = true;
        ds().supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
    }
    
    function _initBookData() internal {
        ps().baseToGender[1] = Gender.Male;
        ps().baseToGender[2] = Gender.Male;
        ps().baseToGender[3] = Gender.Male;
        ps().baseToGender[4] = Gender.Male;
        ps().baseToGender[5] = Gender.Female;
        ps().baseToGender[6] = Gender.Female;
        ps().baseToGender[7] = Gender.Female;
        ps().baseToGender[8] = Gender.Female;
        ps().baseToGender[9] = Gender.Zombie;
        ps().baseToGender[10] = Gender.Ape;
        ps().baseToGender[11] = Gender.Alien;
        
        ps().genderToBases[Gender.Human] = [1,2,3,4,5,6,7,8];
        ps().genderToBases[Gender.Male] = [1,2,3,4];
        ps().genderToBases[Gender.Female] = [5,6,7,8];
        ps().genderToBases[Gender.Zombie] = [9];
        ps().genderToBases[Gender.Ape] = [10];
        ps().genderToBases[Gender.Alien] = [11];

        uint8[11] memory baseRanges = [1,2,3,4,5,6,7,8,9,10,11];
        
        for (uint i = 0; i < baseRanges.length; i++) {
            ps().validBases.add(baseRanges[i]);
        }

        uint8[20] memory hats = [16, 22, 25, 37, 38, 46, 47, 51, 53, 60, 63, 67, 75, 76, 90, 105, 107, 110, 113, 121];
        
        for (uint8 i = 0; i < hats.length; i++) {
            ps().isHat[hats[i]] = true;
        }
        
        ps().assetSlotToTraitType = [
            "Sex",
            "Mouth / Lips",
            "Face",
            "Neck",
            "Beard",
            "Ears",
            "Hair",
            "Mouth Accessory",
            "Eyes",
            "Nose"
        ];
        
        ps().palette = hex'000000ff713f1dff8b532cff562600ff723709ffae8b61ffb69f82ff86581effa77c47ffdbb180ffe7cba9ffa66e2cffd29d60ffead9d9ffffffffffa58d8dffc9b2b2ff4a1201ff5f1d09ff711010ff7da269ff9bbc88ff5e7253ffff0000ff352410ff856f56ff6a563fffa98c6bffc8fbfbff9be0e0fff1ffffff75bdbdffd6000033692f08ff28b143ff794b11ff502f05ff00000099d60000ffc6c6c6ffdedede80e25b26ff80dbdaffca4e11ff933709ff0000004d86581e4d353535ff515151ff221e1766710cc7ff000000915c390fffc77514ff595959ff0040ffffdfdfdfff8c0d5bff690c45ffad2160ff555555ff0060c3ffe4eb17ff3cc300ffd60404ff8119b7ffb261dcff2c9541ff296434ffc9c9c9ffb1b1b1ff8d8d8dffb4b4b4ffdc1d1dff1a43c8ff1637a4ff142c7cffc28946ff2a2a2affe22626ff26314affffd800ff4c4c4cff636363ff000000403d2f1effffd926ffcae7fe701a6ed5ff855114ffbababa80683c08ff68461fffffc926ffd7d7d7fff0f0f0ff328dfdfffd3232ff2858b1ff2c5195ff293e64ff85561eff2d6b62ff005580ff229000ffc42110ff2c779599fff68eff8d5b4099ffba00ffff2a00ffe65700ffb500af99cd00cbff1c1a00ff534c00ffff8ebeff2c95419951360cff96200526';
    }
    
    function initRoles() internal {
        _grantRoleStr("admin", msg.sender);
        _grantRoleStr("admin", 0xC2172a6315c1D7f6855768F843c420EbB36eDa97);
        
        _setRoleAdminStr("admin", "admin");
        _setRoleAdminStr("nft_admin", "admin");
        
        _grantRoleStr("nft_admin", 0xB70CC02cBD58C313793c971524ad066359fD1E8e);
        _grantRoleStr("nft_admin", 0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112);
        _grantRoleStr("nft_admin", 0xC2172a6315c1D7f6855768F843c420EbB36eDa97);
    }
    
    function testMint() internal {
        // require(block.chainid != 1);
        
        // if (!_exists(42502163051250041496338)) {
        //     mintPunkToUser(msg.sender, 42502163051250041496338);
        // }
        
        // if (!_exists(51946040600240328820992)) {
        //     mintPunkToUser(0x84a7aBa931CE5dCE911eFbF9473042E851ffD699, 51946040600240328820992);
        //     bk().punkIdToName[51946040600240328820992] = "Piv punk";
        // }
        
        // if (!_exists(14167964139737663424256)) {
        //     mintPunkToUser(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, 14167964139737663424256);
        //     upgradePunkToLevel(14167964139737663424256, 100);
        // }
    }
    
    function isInitialized() external view returns (bool) {
        return gs().initialized;
    }
    
    function setInitialized(bool _initialized) external onlyOwner {
        gs().initialized = _initialized;
    }
    
    function mintPunkToUser(address to, uint punkId) internal {
        _mint(to, punkId);
        
        if (bk().userToPrimaryPunkId[to] == 0) {
            bk().userToPrimaryPunkId[to] = punkId;
        }
    }
    
    function _punkIdToPunkUpradeLevel(uint tokenId) internal view returns (uint) {
        return _getTokenExtraData(tokenId);
    }    
    
    function upgradePunkToLevel(uint punkId, uint level) internal returns (bool) {
        _setTokenExtraData(punkId, uint96(level));
        delete bk().punkIdToPunkDamageEvents[punkId];
        
        emit UpgradePunk(punkId, _punkIdToPunkUpradeLevel(punkId));
        
        return true;
    }
    
    function initOperatorFilter() internal {
        bk().withdrawAddress = block.chainid == 1 ?
                0x542430459de4A821C32DaA89b00dE3f2A8Cf43b9 :
                0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
        
        ERC2981Storage.layout().defaultRoyaltyBPS = 500;
        ERC2981Storage.layout().defaultRoyaltyReceiver = bk().withdrawAddress;
        
        bk().operatorFilteringEnabled = true;
        ds().supportedInterfaces[type(IERC2981).interfaceId] = true;
        _registerForOperatorFiltering();
    }
}