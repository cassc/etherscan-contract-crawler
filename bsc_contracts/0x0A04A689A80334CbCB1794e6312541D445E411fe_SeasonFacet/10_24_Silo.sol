/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Life.sol";
import "../../../libraries/LibInternal.sol";

/**
 * @title Silo
 **/
contract Silo is Life {
    using Decimal for Decimal.D256;

    uint256 private constant BASE = 1e12;
    uint256 private constant BURN_BASE = 1e20;
    uint256 private constant BIG_BASE = 1e24;

    /**
     * Getters
     **/

    function seasonOfPlenty(uint32 _s) external view returns (uint256) {
        return s.sops[_s];
    }

    function paused() public view returns (bool) {
        return s.paused;
    }

    /**
     * Internal
     **/

    // Silo

    function stepSilo(uint256 amount) internal {
        rewardTopcorns(amount);
    }

    function rewardTopcorns(uint256 amount) private {
        if (s.s.stalk == 0 || amount == 0) return;
        s.s.stalk = s.s.stalk + (amount * C.getStalkPerTopcorn());
        s.s.topcorns = s.s.topcorns + amount;
        s.topcorn.deposited = s.topcorn.deposited + amount;
        s.s.seeds = s.s.seeds + (amount * C.getSeedsPerTopcorn());
    }

    // Season of Plenty

    function rewardBNB(uint256 amount) internal {
        uint256 base;
        if (s.sop.base == 0) {
            base = amount * BIG_BASE;
            s.sop.base = BURN_BASE;
        } else base = (amount * s.sop.base) / s.sop.wbnb;

        // Award bnb to claimed stalk holders
        uint256 basePerStalk = base / s.r.roots;
        base = basePerStalk * s.r.roots;
        s.sops[s.r.start] = s.sops[s.r.start] + basePerStalk;

        // Update total state
        s.sop.wbnb = s.sop.wbnb + amount;
        s.sop.base = s.sop.base + base;
        if (base > 0) s.sop.last = s.r.start;
    }
}