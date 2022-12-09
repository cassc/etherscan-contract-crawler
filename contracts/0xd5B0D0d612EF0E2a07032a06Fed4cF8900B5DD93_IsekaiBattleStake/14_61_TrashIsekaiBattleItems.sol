// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import {IsekaiBattleWeapon} from './IsekaiBattleWeapon.sol';
import {IsekaiBattleArmor} from './IsekaiBattleArmor.sol';
import './interface/IIsekaiBattleSeeds.sol';
import {ISGData, IISBStaticData} from './extensions/ISGData.sol';

contract TrashIsekaiBattleItems is ReentrancyGuard, Context {
    event TrashWeapons(address indexed user, uint256[] ids, uint256[] values);
    event TrashArmors(address indexed user, uint256[] ids, uint256[] values);

    IsekaiBattleArmor public immutable AMR;
    IsekaiBattleWeapon public immutable WPN;

    constructor(IsekaiBattleArmor _AMR, IsekaiBattleWeapon _WPN) {
        AMR = _AMR;
        WPN = _WPN;
    }

    function _trashWeapons(uint256[] calldata ids, uint256[] calldata values) internal virtual {
        WPN.burnBatchAdmin(_msgSender(), ids, values);
        emit TrashWeapons(_msgSender(), ids, values);
    }

    function _trashArmors(uint256[] calldata ids, uint256[] calldata values) internal virtual {
        AMR.burnBatchAdmin(_msgSender(), ids, values);
        emit TrashArmors(_msgSender(), ids, values);
    }

    function trashWeapons(uint256[] calldata ids, uint256[] calldata values) public virtual nonReentrant {
        _trashWeapons(ids, values);
    }

    function trashArmors(uint256[] calldata ids, uint256[] calldata values) public virtual nonReentrant {
        _trashArmors(ids, values);
    }

    function trashItems(
        uint256[] calldata weaponIds,
        uint256[] calldata weaponValues,
        uint256[] calldata armorIds,
        uint256[] calldata armorValues
    ) public virtual nonReentrant {
        _trashWeapons(weaponIds, weaponValues);
        _trashArmors(armorIds, armorValues);
    }
}