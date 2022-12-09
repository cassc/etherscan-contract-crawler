// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

//v0.0.2

import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import {IsekaiBattleWeapon} from './IsekaiBattleWeapon.sol';
import {IsekaiBattleArmor} from './IsekaiBattleArmor.sol';
import {IsekaiBattleBag} from './IsekaiBattleBag.sol';
import './interface/IIsekaiBattleSeeds.sol';
import {IsekaiBattle} from './IsekaiBattle.sol';
import {Random} from './Random.sol';

contract IsekaiBattleStake is IERC721Receiver, ReentrancyGuard, Context, AccessControlEnumerable {
    bytes32 public constant INFO_SETTER_ROLE = keccak256('INFO_SETTER_ROLE');

    //events
    event Stake(address indexed user, uint64 regionId, uint256[] tokenId);
    event Unstake(address indexed user, uint64 regionId, uint256[] tokenId);
    event ClaimWeapons(address indexed user, uint64 regionId, uint256[] detailsCount);
    event ClaimArmors(address indexed user, uint64 regionId, uint256[] detailsCount);
    event ClaimSeed(address indexed user, uint64 regionId, uint256 tokenId);
    event ClaimComplete(address indexed user);

    struct ClaimInfo {
        uint256 tokenId;
        uint256[] ratio;
    }

    struct RegionInfo {
        uint256[] WeaponCounts;
        uint256[] ArmorCounts;
        uint256[] SeedPers;
        ClaimInfo[] WeaponDetails;
        ClaimInfo[] ArmorDetails;
        uint256 WeaponInterval;
        uint256 ArmorInterval;
        uint256 SeedInterval;
        uint256 MaxStakingCharacters;
        bool active;
    }

    struct StakingRequest {
        uint64 regionId;
        uint256[] tokenIds;
    }

    struct StakingInfo {
        uint256 claimTimes;
        uint256 stakingCharactorCounts;
        uint64[] stakingRegionIds;
    }

    struct ActionCount {
        uint64 claim;
        uint64 claimPlus;
        uint64 stake;
        uint64 wpnClaim;
        uint64 armClaim;
        uint64 seedClaim;
        uint64 wpn;
        uint64 arm;
        uint64 seed;
    }

    RegionInfo[] public regionInfos;
    mapping(address => mapping(uint64 => uint256[])) public stakingTokenIds;
    mapping(address => StakingInfo) public stakingInfos;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => ActionCount) public actionCounts;

    IsekaiBattle public immutable ISB;
    IIsekaiBattleSeeds public immutable SED;
    IsekaiBattleArmor public immutable AMR;
    IsekaiBattleWeapon public immutable WPN;
    IsekaiBattleBag public immutable BAG;
    Random public immutable RDM;

    uint256 public maxStakingCharacters = 15;
    uint256 public minGetSeedCharacters = 3;

    constructor(
        IsekaiBattle _ISB,
        IIsekaiBattleSeeds _SED,
        IsekaiBattleArmor _AMR,
        IsekaiBattleWeapon _WPN,
        IsekaiBattleBag _BAG,
        Random _RDM
    ) {
        ISB = _ISB;
        SED = _SED;
        AMR = _AMR;
        WPN = _WPN;
        BAG = _BAG;
        RDM = _RDM;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(INFO_SETTER_ROLE, _msgSender());
    }

    function addRegionInfo(RegionInfo memory info) public virtual onlyRole(INFO_SETTER_ROLE) {
        regionInfos.push(info);
    }

    function setRegionInfo(uint256 index, RegionInfo memory info) public virtual onlyRole(INFO_SETTER_ROLE) {
        regionInfos[index] = info;
    }

    function setMaxStakingCharacters(uint256 value) public virtual onlyRole(INFO_SETTER_ROLE) {
        maxStakingCharacters = value;
    }

    function setMinGetSeedCharacters(uint256 value) public virtual onlyRole(INFO_SETTER_ROLE) {
        minGetSeedCharacters = value;
    }

    function getRegionInfosLength() public view virtual returns (uint256) {
        return regionInfos.length;
    }

    function stakingTokenIdsLength(address account, uint64 regionId) public view virtual returns (uint256) {
        return stakingTokenIds[account][regionId].length;
    }

    function stake(StakingRequest[] memory _stakingInfo) public virtual {
        require(ISB.isApprovedForAll(_msgSender(), address(this)), 'not approved');
        actionCounts[_msgSender()].stake++;

        if (stakingInfos[_msgSender()].stakingCharactorCounts > 0) {
            claim();
            for (uint256 i = 0; i < stakingInfos[_msgSender()].stakingRegionIds.length; i++) {
                _unstake(stakingTokenIds[_msgSender()][stakingInfos[_msgSender()].stakingRegionIds[i]]);
                emit Unstake(
                    _msgSender(),
                    stakingInfos[_msgSender()].stakingRegionIds[i],
                    stakingTokenIds[_msgSender()][stakingInfos[_msgSender()].stakingRegionIds[i]]
                );
            }
        }

        delete stakingInfos[_msgSender()].stakingRegionIds;
        uint256 allTokenCount = 0;

        for (uint256 i = 0; i < _stakingInfo.length; i++) {
            allTokenCount += _stakingInfo[i].tokenIds.length;
            require(allTokenCount <= maxStakingCharacters, 'max character');
            for (uint256 j = 0; j < _stakingInfo[i].tokenIds.length; j++) {
                ISB.safeTransferFrom(_msgSender(), address(this), _stakingInfo[i].tokenIds[j]);
            }
            stakingInfos[_msgSender()].stakingRegionIds.push(_stakingInfo[i].regionId);
            stakingTokenIds[_msgSender()][_stakingInfo[i].regionId] = _stakingInfo[i].tokenIds;
            emit Stake(_msgSender(), _stakingInfo[i].regionId, _stakingInfo[i].tokenIds);
        }
        stakingInfos[_msgSender()].stakingCharactorCounts = allTokenCount;
        stakingInfos[_msgSender()].claimTimes = block.timestamp;
    }

    function claim() public virtual nonReentrant {
        require(stakingInfos[_msgSender()].stakingRegionIds.length > 0, 'not stake');
        uint256 elapsed = block.timestamp - stakingInfos[_msgSender()].claimTimes;
        uint256 stakingCharactorCount = stakingInfos[_msgSender()].stakingCharactorCounts;
        ActionCount memory origin = actionCounts[_msgSender()];

        for (uint256 i = 0; i < stakingInfos[_msgSender()].stakingRegionIds.length; i++) {
            uint64 regionId = stakingInfos[_msgSender()].stakingRegionIds[i];
            RegionInfo memory targetRegionInfo = regionInfos[regionId];
            if (!targetRegionInfo.active) continue;
            uint256[] memory tokenIds = stakingTokenIds[_msgSender()][regionId];
            uint256 ratioIndex = Math.min(tokenIds.length, 5);
            (uint256 weaponCount, uint256 armorCount, , , , ) = getEstimate();
            uint256 seedPer = (elapsed > targetRegionInfo.SeedInterval)
                ? targetRegionInfo.SeedPers[stakingCharactorCount]
                : 0;
            stakingInfos[_msgSender()].claimTimes = block.timestamp;

            if (
                (weaponCount > 0 || armorCount > 0 || seedPer > 0) &&
                origin.claimPlus == actionCounts[_msgSender()].claimPlus
            ) {
                actionCounts[_msgSender()].claimPlus++;
            }

            if (weaponCount > 0) {
                uint256[] memory detailsCount = new uint256[](targetRegionInfo.WeaponDetails.length);
                for (uint256 j = 0; j < weaponCount; j++) {
                    uint256 randomNumber = RDM.getRandomNumber() % 1000000;
                    uint256 ratioCount = 0;
                    for (uint256 k = 0; k < targetRegionInfo.WeaponDetails.length; k++) {
                        ratioCount += targetRegionInfo.WeaponDetails[k].ratio[ratioIndex];
                        if (ratioCount > randomNumber) {
                            detailsCount[k]++;
                            break;
                        }
                    }
                }
                for (uint256 j = 0; j < detailsCount.length; j++) {
                    if (detailsCount[j] > 0) {
                        WPN.mint(_msgSender(), targetRegionInfo.WeaponDetails[j].tokenId, detailsCount[j], '');
                    }
                }
                if (origin.wpnClaim == actionCounts[_msgSender()].wpnClaim) {
                    actionCounts[_msgSender()].wpnClaim++;
                }
                actionCounts[_msgSender()].wpn += uint64(weaponCount);
                emit ClaimWeapons(_msgSender(), regionId, detailsCount);
            }
            if (armorCount > 0) {
                uint256[] memory detailsCount = new uint256[](targetRegionInfo.ArmorDetails.length);
                for (uint256 j = 0; j < armorCount; j++) {
                    uint256 randomNumber = RDM.getRandomNumber() % 1000000;
                    uint256 ratioCount = 0;
                    for (uint256 k = 0; k < targetRegionInfo.ArmorDetails.length; k++) {
                        ratioCount += targetRegionInfo.ArmorDetails[k].ratio[ratioIndex];
                        if (ratioCount > randomNumber) {
                            detailsCount[k]++;
                            break;
                        }
                    }
                }
                for (uint256 j = 0; j < detailsCount.length; j++) {
                    if (detailsCount[j] > 0) {
                        AMR.mint(_msgSender(), targetRegionInfo.ArmorDetails[j].tokenId, detailsCount[j], '');
                    }
                }
                if (origin.armClaim == actionCounts[_msgSender()].armClaim) {
                    actionCounts[_msgSender()].armClaim++;
                }
                actionCounts[_msgSender()].arm += uint64(armorCount);
                emit ClaimArmors(_msgSender(), regionId, detailsCount);
            }
            if (stakingCharactorCount >= minGetSeedCharacters && seedPer > 0) {
                uint256 length = ISB.getStatusMastersLength();
                for (uint256 j = 0; j < tokenIds.length; j++) {
                    uint256 random = RDM.getRandomNumber() % 1000000;
                    if (random < seedPer) {
                        SED.mint(_msgSender(), (random % length) * 10, 1, '');
                        actionCounts[_msgSender()].seed++;
                        if (origin.seedClaim == actionCounts[_msgSender()].seedClaim) {
                            actionCounts[_msgSender()].seedClaim++;
                        }
                        emit ClaimSeed(_msgSender(), regionId, (random % length) * 10);
                    }
                }
            }
        }
        actionCounts[_msgSender()].claim++;
        emit ClaimComplete(_msgSender());
    }

    function getEstimate()
        public
        view
        virtual
        returns (
            uint256,
            uint256,
            bool,
            bool,
            uint256,
            uint256
        )
    {
        uint256 weaponCount = 0;
        uint256 armorCount = 0;
        uint256 stakingCharactorCount = stakingInfos[_msgSender()].stakingCharactorCounts;
        uint256 elapsed = block.timestamp - stakingInfos[_msgSender()].claimTimes;
        uint256 wpnBagCount = BAG.getWpnBagCount(_msgSender());
        uint256 armBagCount = BAG.getArmBagCount(_msgSender());
        for (uint256 i = 0; i < stakingInfos[_msgSender()].stakingRegionIds.length; i++) {
            RegionInfo memory targetRegionInfo = regionInfos[stakingInfos[_msgSender()].stakingRegionIds[i]];
            if (!targetRegionInfo.active) continue;
            weaponCount +=
                ((elapsed / targetRegionInfo.WeaponInterval) * targetRegionInfo.WeaponCounts[stakingCharactorCount]) /
                10000;
            armorCount +=
                ((elapsed / targetRegionInfo.ArmorInterval) * targetRegionInfo.ArmorCounts[stakingCharactorCount]) /
                10000;
            if (
                WPN.balanceOfAll(_msgSender()) + weaponCount > wpnBagCount &&
                AMR.balanceOfAll(_msgSender()) + armorCount > armBagCount
            ) {
                break;
            }
        }
        return (
            WPN.balanceOfAll(_msgSender()) + weaponCount > wpnBagCount
                ? (wpnBagCount > WPN.balanceOfAll(_msgSender()) ? wpnBagCount - WPN.balanceOfAll(_msgSender()) : 0)
                : weaponCount,
            AMR.balanceOfAll(_msgSender()) + armorCount > armBagCount
                ? (armBagCount > AMR.balanceOfAll(_msgSender()) ? armBagCount - AMR.balanceOfAll(_msgSender()) : 0)
                : armorCount,
            WPN.balanceOfAll(_msgSender()) + weaponCount > wpnBagCount,
            AMR.balanceOfAll(_msgSender()) + armorCount > armBagCount,
            weaponCount,
            armorCount
        );
    }

    function unstake(uint256[] memory tokenIds) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = tokenOwners[tokenIds[i]];
            tokenOwners[tokenIds[i]] = address(0);
            ISB.safeTransferFrom(address(this), owner, tokenIds[i]);
        }
    }

    function _unstake(uint256[] memory tokenIds) internal virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenOwners[tokenIds[i]] == _msgSender());
            tokenOwners[tokenIds[i]] = address(0);
            ISB.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(address(this) == operator, 'not me');
        tokenOwners[tokenId] = from;
        return this.onERC721Received.selector;
    }
}