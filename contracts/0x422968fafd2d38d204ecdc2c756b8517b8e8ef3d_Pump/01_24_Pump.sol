// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Access} from "../Access.sol";
import {PumpStorageExt} from "./PumpStorageExt.sol";
import {DataTypes} from "./lib/DataTypes.sol";
import {IPump} from "./interfaces/IPump.sol";

contract Pump is Access, ERC721HolderUpgradeable, PumpStorageExt, IPump {

    function Pump__init(address _admin, address _dga) public initializer {
        __Access_init(_admin);
        dga = _dga;
        lockPeriod = 365 days;
        PumpRateMin = 20_000;
        PumpRateMax = 100_000;
        PumpStep = 32;
        PumpHill = 480;
    }

    function pump(uint[] memory ids) external virtual override {
        address sender = msg.sender;
        DataTypes.BoostItem[] storage userBoosted = boosted[sender];
        uint createdAt = block.timestamp;
        for (uint i = 0; i < ids.length; i++) {
            IERC721Upgradeable(dga).safeTransferFrom(sender, address(this), ids[i]);
            userBoosted.push(DataTypes.BoostItem({
                owner: sender,
                id: uint32(ids[i]),
                lockTime: uint40(createdAt),
                released: false
            }));
        }
        totalNo += ids.length;
        boostedNo[sender] += ids.length;
        emit Pumped(sender, ids);

    }

    
    function drain() external virtual override {
        address sender = msg.sender;
        DataTypes.BoostItem[] memory userBoosted = boosted[sender];
        uint40 lockTime = uint40(block.timestamp - lockPeriod);
        uint unlockNo;
        for (uint i = 0; i < userBoosted.length; i++) {
            if (userBoosted[i].lockTime <= lockTime && !userBoosted[i].released) {
                unlockNo++;
            }
        }

        uint[] memory unlockIds = new uint[](unlockNo);
        uint j;
        for (uint i = 0; i < userBoosted.length; i++) {
            if (userBoosted[i].lockTime <= lockTime && !userBoosted[i].released) {
                uint id = uint(userBoosted[i].id);
                IERC721Upgradeable(dga).safeTransferFrom(address(this), sender, id);
                boosted[sender][i].released = true;
                unlockIds[j] = id;
                j++;
            } 
        }

        totalNo -= unlockNo;
        boostedNo[sender] -= unlockNo;
        emit Drained(sender, unlockIds);
    }

    function getPumpTier() public view returns (uint) {
        return totalNo / PumpStep;
    }

    function getNextPumpTier() public view returns (uint) {
        return getPumpTier() + 1;
    }

    function getPumpRate() public view returns (uint) {
        uint pumpRate = PumpRateMin + getPumpTier() * (PumpRateMax - PumpRateMin) * PumpStep / PumpHill;
        return pumpRate > PumpRateMax ? PumpRateMax : pumpRate;
    }

    function getNextPumpRate() public view returns (uint) {
        uint nextPumpRate = PumpRateMin + getNextPumpTier() * (PumpRateMax - PumpRateMin) * PumpStep / PumpHill;
        return nextPumpRate > PumpRateMax ? PumpRateMax : nextPumpRate;
    }

    function getRequiredDgaNoTillNextTier() public view returns (uint) {
        return (totalNo / PumpStep + 1) * PumpStep - totalNo;
    }

    function getPumpInfo() public view returns (DataTypes.BoostInfo memory vars) {
        vars.curTier = getPumpTier();
        vars.curPumpRate = getPumpRate();
        vars.nextTier = getNextPumpTier();
        vars.nextPumpRate = getNextPumpRate();
        vars.dgaRequired = getRequiredDgaNoTillNextTier();
        vars.totalPumped = totalNo;
    }

    function getUserBoosted(address user) external view returns (DataTypes.ViewBoostItem[] memory) {
        DataTypes.BoostItem[] memory userBoosted = boosted[user];
        DataTypes.ViewBoostItem[] memory varv = new DataTypes.ViewBoostItem[](userBoosted.length);
        for (uint i = 0; i < userBoosted.length; i++) {
            varv[i] = DataTypes.ViewBoostItem({
                owner: userBoosted[i].owner,
                id: userBoosted[i].id,
                lockTime: userBoosted[i].lockTime,
                unlockTime: userBoosted[i].lockTime + uint40(lockPeriod),
                released: userBoosted[i].released
            });
        }
        return varv;
    }

    function version() external virtual override view returns (string memory) {
        return "v1.0";
    }
}