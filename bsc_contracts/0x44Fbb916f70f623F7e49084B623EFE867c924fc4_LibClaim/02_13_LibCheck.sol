/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakePair.sol";
import "./LibAppStorage.sol";
import "../interfaces/ITopcorn.sol";

/**
 * @title Check Library verifies Farmer's balances are correct.
 **/
library LibCheck {
    function topcornBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(ITopcorn(s.c.topcorn).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.topcorn.deposited + s.topcorn.withdrawn, "Check: TopCorn balance fail.");
    }

    function lpBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }

    function balanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(ITopcorn(s.c.topcorn).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.topcorn.deposited + s.topcorn.withdrawn, "Check: TopCorn balance fail.");
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }
}