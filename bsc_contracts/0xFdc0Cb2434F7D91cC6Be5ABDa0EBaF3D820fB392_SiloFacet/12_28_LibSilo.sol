/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @title Lib Silo
 **/
library LibSilo {
    using Decimal for Decimal.D256;

    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);

    /**
     * Silo
     **/

    function depositSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        incrementBalanceOfStalk(account, stalk);
        incrementBalanceOfSeeds(account, seeds);
    }

    function withdrawSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        decrementBalanceOfStalk(account, stalk);
        decrementBalanceOfSeeds(account, seeds);
    }

    function incrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds + seeds;
        s.a[account].s.seeds = s.a[account].s.seeds + seeds;
    }

    function incrementBalanceOfStalk(address account, uint256 stalk) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 roots;
        if (s.s.roots == 0) roots = stalk * C.getRootsBase();
        else roots = (s.s.roots * stalk) / s.s.stalk;

        s.s.stalk = s.s.stalk + stalk;
        s.a[account].s.stalk = s.a[account].s.stalk + stalk;

        s.s.roots = s.s.roots + roots;
        s.a[account].roots = s.a[account].roots + roots;
    }

    function decrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds - seeds;
        s.a[account].s.seeds = s.a[account].s.seeds - seeds;
    }

    function decrementBalanceOfStalk(address account, uint256 stalk) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (stalk == 0) return;
        uint256 roots = (s.a[account].roots * stalk - 1) / s.a[account].s.stalk + 1;

        s.s.stalk = s.s.stalk - stalk;
        s.a[account].s.stalk = s.a[account].s.stalk - stalk;

        s.s.roots = s.s.roots - roots;
        s.a[account].roots = s.a[account].roots - roots;
    }

    function updateBalanceOfRainStalk(address account) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.r.raining) return;
        if (s.a[account].roots < s.a[account].sop.roots) {
            s.r.roots = s.r.roots - (s.a[account].sop.roots - s.a[account].roots);
            s.a[account].sop.roots = s.a[account].roots;
        }
    }

    function stalkReward(uint256 seeds, uint32 seasons) internal pure returns (uint256) {
        return seeds * seasons;
    }

    function season() internal view returns (uint32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.season.current;
    }
}