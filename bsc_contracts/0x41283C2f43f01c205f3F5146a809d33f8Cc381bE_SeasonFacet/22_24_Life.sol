/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../interfaces/pancake/IPancakePair.sol";
import "../../AppStorage.sol";
import "../../ReentrancyGuard.sol";
import "../../../C.sol";
import "../../../interfaces/ITopcorn.sol";

/**
 * @title Life
 **/
contract Life is ReentrancyGuard {
    /**
     * Getters
     **/

    // Contracts

    function topcorn() public view returns (ITopcorn) {
        return ITopcorn(s.c.topcorn);
    }

    function pair() public view returns (IPancakePair) {
        return IPancakePair(s.c.pair);
    }

    function pegPair() public view returns (IPancakePair) {
        return IPancakePair(s.c.pegPair);
    }

    // Time

    function time() external view returns (Storage.Season memory) {
        return s.season;
    }

    function season() public view returns (uint32) {
        return s.season.current;
    }

    function withdrawSeasons() external view returns (uint8) {
        return s.season.withdrawSeasons;
    }

    function seasonTime() public view virtual returns (uint32) {
        if (block.timestamp < s.season.start) return 0;
        if (s.season.period == 0) return type(uint32).max;
        return uint32((block.timestamp - s.season.start) / s.season.period);
    }

    function incentiveTime() internal view returns (uint256) {
        uint256 timestamp = block.timestamp - (s.season.start + (s.season.period * season()));
        uint256 maxTime = s.season.maxTimeMultiplier;
        if (maxTime > 100) maxTime = 100;
        if (timestamp > maxTime) timestamp = maxTime;
        return timestamp;
    }

    /**
     * Internal
     **/
    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) {
        (uint256 newHarvestable, uint256 siloReward) = (0, 0);

        if (s.f.harvestable < s.f.pods) {
            uint256 notHarvestable = s.f.pods - s.f.harvestable;
            newHarvestable = (newSupply * C.getHarvestPercentage()) / 1e18;
            newHarvestable = newHarvestable > notHarvestable ? notHarvestable : newHarvestable;
            mintToHarvestable(newHarvestable);
        }

        if (s.s.seeds == 0 && s.s.stalk == 0) return (newHarvestable, 0);
        siloReward = newSupply - newHarvestable;
        if (siloReward > 0) {
            mintToSilo(siloReward);
        }
        return (newHarvestable, siloReward);
    }

    function mintToSilo(uint256 amount) internal {
        if (amount > 0) {
            topcorn().mint(address(this), amount);
        }
    }

    function mintToHarvestable(uint256 amount) internal {
        topcorn().mint(address(this), amount);
        s.f.harvestable = s.f.harvestable + amount;
    }

    function mintToAccount(address account, uint256 amount) internal {
        topcorn().mint(account, amount);
    }

    /**
     * Soil
     **/

    function setSoil(uint256 amount) internal returns (int256) {
        int256 soil = int256(s.f.soil);
        s.f.soil = amount;
        return int256(amount) - soil;
    }

    function getMinSoil(uint256 amount) internal view returns (uint256 minSoil) {
        minSoil = (amount * 100) / (100 + s.w.yield);
    }
}