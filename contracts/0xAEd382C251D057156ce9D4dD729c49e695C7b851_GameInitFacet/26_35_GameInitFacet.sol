// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibStorage.sol";
import "hardhat/console.sol";

import "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { IERC165 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC165.sol";

import {IERC1155} from "@solidstate/contracts/interfaces/IERC1155.sol";
import {IERC1155Metadata} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";
import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import {ERC2981} from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import { ERC1155DInternal } from "./ERC1155D/ERC1155DInternal.sol";
import { GameInternalFacet } from "./GameInternalFacet.sol";

contract GameInitFacet is WithStorage, UsingDiamondOwner, OperatorFilterer,
    ERC1155DInternal, GameInternalFacet {
    function isInitialized() external view returns (bool) {
        return gs().initialized;
    }
    
    function setInitialized(bool _initialized) external onlyOwner {
        gs().initialized = _initialized;
    }
    
    function initOperatorFilter() internal {
        ERC2981Storage.layout().defaultRoyaltyBPS = 500;
        ERC2981Storage.layout().defaultRoyaltyReceiver = gs().withdrawAddress;
        
        gs().operatorFilteringEnabled = true;
        ds().supportedInterfaces[type(IERC2981).interfaceId] = true;
        _registerForOperatorFiltering();
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
    
    function init(address _bookContract) external {
        if (gs().initialized) return;
        
        gs().bookContract = _bookContract;
        
        _setName("Babylon Item");
        _setSymbol("BI");
        
        gs().seedBlockGap = 1;
        
        gs().withdrawAddress = block.chainid == 1 ?
                0x542430459de4A821C32DaA89b00dE3f2A8Cf43b9 :
                0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
        
        gs().auctionItemSlug = "regular_key";
        
        acs().timeBuffer = 1 minutes;
        acs().reservePrice = 0.005 ether;
        acs().minBidAmountIfCurrentBidZero = 0.005 ether;
        acs().minBidIncrementPercentage = 10;
        acs().auctionDuration = 1 hours;
        acs().auctionEnabled = block.chainid == 1 ? false : true;
        
        if (block.chainid != 1) testMint();
        if (block.chainid == 1) devMint();
        
        initOperatorFilter();
        
        initRoles();
        
        initERC165();
    }
    
    function initERC165() internal {
        ds().supportedInterfaces[type(IERC165).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds().supportedInterfaces[type(IERC173).interfaceId] = true;
        
        ds().supportedInterfaces[type(IERC1155).interfaceId] = true;
        ds().supportedInterfaces[type(IERC1155Metadata).interfaceId] = true;
    }
    
    function devMint() internal {
        require(block.chainid == 1, "Must be on main");
        
        _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("regular_key"), 10, "");
        _mint(0xB70CC02cBD58C313793c971524ad066359fD1E8e, slugToTokenId("regular_key"), 10, "");
        _mint(0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112, slugToTokenId("regular_key"), 10, "");
    }
    
    function testMint() internal {
        // require(block.chainid != 1, "Can't be on main");
        
        // uint auctionKeyId = slugToTokenId(gs().auctionItemSlug);
        
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, auctionKeyId, 100, "");
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("key_fragment"), 100, "");
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("skeleton_key"), 100, "");
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("diamond_skeleton_key"), 100, "");
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("book_upgrade"), 100, "");
        // _mint(0xC2172a6315c1D7f6855768F843c420EbB36eDa97, slugToTokenId("book_name_tag"), 100, "");
        
        // _mint(0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112, auctionKeyId, 100, "");
        // _mint(0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112, slugToTokenId("key_fragment"), 100, "");
        // _mint(0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112, slugToTokenId("skeleton_key"), 100, "");
        // _mint(0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112, slugToTokenId("diamond_skeleton_key"), 100, "");
        
        // _mint(0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8, auctionKeyId, 100, "");
        // _mint(0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8, slugToTokenId("key_fragment"), 100, "");
        // _mint(0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8, slugToTokenId("skeleton_key"), 100, "");
        // _mint(0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8, slugToTokenId("diamond_skeleton_key"), 100, "");
        
        // _mint(0x84a7aBa931CE5dCE911eFbF9473042E851ffD699, auctionKeyId, 100, "");
        // _mint(0x84a7aBa931CE5dCE911eFbF9473042E851ffD699, slugToTokenId("key_fragment"), 100, "");
        // _mint(0x84a7aBa931CE5dCE911eFbF9473042E851ffD699, slugToTokenId("skeleton_key"), 100, "");
        // _mint(0x84a7aBa931CE5dCE911eFbF9473042E851ffD699, slugToTokenId("diamond_skeleton_key"), 100, "");
        
        // _mint(msg.sender, auctionKeyId, 100, "");
        // _mint(msg.sender, slugToTokenId("key_fragment"), 100, "");
        // _mint(msg.sender, slugToTokenId("skeleton_key"), 100, "");
        // _mint(msg.sender, slugToTokenId("diamond_skeleton_key"), 100, "");
    }
}