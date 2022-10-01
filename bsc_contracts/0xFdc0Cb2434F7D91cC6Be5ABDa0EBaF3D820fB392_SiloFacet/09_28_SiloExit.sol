/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../interfaces/pancake/IPancakePair.sol";
import "../../../interfaces/IWBNB.sol";
import "../../../interfaces/ITopcorn.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibInternal.sol";
import "../../../libraries/LibMarket.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../C.sol";

/**
 * @title Silo Exit
 **/
contract SiloExit {
    AppStorage internal s;

    /**
     * Contracts
     **/

    function wbnb() external view returns (IWBNB) {
        return IWBNB(s.c.wbnb);
    }

    /**
     * Silo
     **/

    function totalStalk() external view returns (uint256) {
        return s.s.stalk;
    }

    function totalRoots() external view returns (uint256) {
        return s.s.roots;
    }

    function totalSeeds() external view returns (uint256) {
        return s.s.seeds;
    }

    function totalFarmableTopcorns() external view returns (uint256) {
        return s.s.topcorns;
    }

    function balanceOfSeeds(address account) external view returns (uint256) {
        return s.a[account].s.seeds + (balanceOfFarmableTopcorns(account) * C.getSeedsPerTopcorn());
    }

    function balanceOfStalk(address account) external view returns (uint256) {
        return s.a[account].s.stalk + balanceOfFarmableStalk(account);
    }

    function balanceOfRoots(address account) public view returns (uint256) {
        return s.a[account].roots;
    }

    function balanceOfGrownStalk(address account) public view returns (uint256) {
        return LibSilo.stalkReward(s.a[account].s.seeds, season() - lastUpdate(account));
    }
    
    function balanceOfFarmableTopcorns(address account) public view returns (uint256 topcorns) {
        uint256 stalk = s.a[account].s.stalk;
        topcorns = balanceOfFarmableTopcornsV3(account, stalk);
    }

    function balanceOfFarmableTopcornsV3(address account, uint256 accountStalk) public view returns (uint256 topcorns) {
        if (s.s.roots == 0) return 0;
        uint256 stalk = (s.s.stalk * balanceOfRoots(account)) / s.s.roots;
        if (stalk <= accountStalk) return 0;
        topcorns = (stalk - accountStalk) / C.getStalkPerTopcorn();
        if (topcorns > s.s.topcorns) return s.s.topcorns;
        return topcorns;
    }

    function balanceOfFarmableStalk(address account) public view returns (uint256) {
        return balanceOfFarmableTopcorns(account) * C.getStalkPerTopcorn();
    }

    function balanceOfFarmableSeeds(address account) external view returns (uint256) {
        return balanceOfFarmableTopcorns(account) * C.getSeedsPerTopcorn();
    }

    function lastUpdate(address account) public view returns (uint32) {
        return s.a[account].lastUpdate;
    }

    /**
     * Season Of Plenty
     **/

    function lastSeasonOfPlenty() external view returns (uint32) {
        return s.sop.last;
    }

    function seasonsOfPlenty() external view returns (Storage.SeasonOfPlenty memory) {
        return s.sop;
    }

    function balanceOfBNB(address account) external view returns (uint256) {
        if (s.sop.base == 0) return 0;
        return (balanceOfPlentyBase(account) * s.sop.wbnb) / s.sop.base;
    }

    function balanceOfPlentyBase(address account) public view returns (uint256) {
        uint256 plenty = s.a[account].sop.base;
        uint32 endSeason = s.a[account].lastSop;
        uint256 plentyPerRoot;
        uint256 rainSeasonBase = s.sops[s.a[account].lastRain];
        if (rainSeasonBase > 0) {
            if (endSeason == s.a[account].lastRain) {
                plentyPerRoot = rainSeasonBase - (s.a[account].sop.basePerRoot);
            } else {
                plentyPerRoot = rainSeasonBase - (s.sops[endSeason]);
                endSeason = s.a[account].lastRain;
            }
            if (plentyPerRoot > 0) plenty = plenty + (plentyPerRoot * s.a[account].sop.roots);
        }

        if (s.sop.last > lastUpdate(account)) {
            plentyPerRoot = s.sops[s.sop.last] - (s.sops[endSeason]);
            plenty = plenty + (plentyPerRoot * balanceOfRoots(account));
        }
        return plenty;
    }

    function balanceOfRainRoots(address account) external view returns (uint256) {
        return s.a[account].sop.roots;
    }

    /**
     * Internal
     **/

    function season() internal view returns (uint32) {
        return s.season.current;
    }
}