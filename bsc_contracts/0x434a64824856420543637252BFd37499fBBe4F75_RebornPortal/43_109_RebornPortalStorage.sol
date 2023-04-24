// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {BitMapsUpgradeable} from "./oz/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {SingleRanking} from "src/lib/SingleRanking.sol";
import {PortalLib} from "src/PortalLib.sol";
import {FastArray} from "src/lib/FastArray.sol";
import {IPiggyBank} from "./interfaces/IPiggyBank.sol";

contract RebornPortalStorage is IRebornDefination {
    //########### Link Contract Address ########## //
    RBT public rebornToken;
    RewardVault public vault;
    address public burnPool;
    IPiggyBank internal piggyBank;

    uint256 internal _season;

    //#### Access #####//
    mapping(address => bool) internal signers;

    //#### Incarnation ######//
    uint256 internal idx;
    mapping(address => uint256) internal rounds;
    mapping(uint256 => LifeDetail) internal details;
    BitMapsUpgradeable.BitMap internal _seeds;
    // season => user address => count
    mapping(uint256 => mapping(address => uint256)) internal _incarnateCounts;
    // max incarnation count
    uint256 internal _incarnateCountLimit;

    //##### Tribute ###### //
    mapping(uint256 => SeasonData) internal _seasonData;

    //#### Refer #######//
    mapping(address => address) internal referrals;
    PortalLib.ReferrerRewardFees internal rewardFees;

    //#### airdrop config #####//
    PortalLib.AirdropConf internal _dropConf;
    PortalLib.VrfConf internal _vrfConf;
    // requestId => request status
    mapping(uint256 => RequestStatus) internal _vrfRequests;
    FastArray.Data internal _pendingDrops;

    //########### NFT ############//
    // tokenId => character property
    mapping(uint256 => PortalLib.CharacterProperty)
        internal _characterProperties;
    // tokenId => token amount required
    mapping(uint256 => uint256) internal _forgeRequiredMaterials;

    //######### Piggy Bank #########//
    // X% to piggyBank piggyBankFee / 10000
    uint256 internal piggyBankFee;

    /// @dev gap for potential variable
    uint256[27] private _gap;
}