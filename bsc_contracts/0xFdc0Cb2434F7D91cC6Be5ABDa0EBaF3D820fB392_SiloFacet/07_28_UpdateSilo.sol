/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./SiloExit.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibInternal.sol";
import "../../../libraries/LibMarket.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../libraries/Silo/LibTopcornSilo.sol";

/**
 * @title Silo Entrance
 **/
contract UpdateSilo is SiloExit {
    event LastUpdate(address indexed account, uint256 season, uint256 grownStalk);

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status = 1;

    /**
     * Update
     **/
    function updateSilo(address account) public payable {
        uint32 update = lastUpdate(account);
        if (update >= season()) return;
        uint256 grownStalk;
        if (s.a[account].s.seeds > 0) grownStalk = balanceOfGrownStalk(account);
        if (s.a[account].roots > 0) {
            farmSops(account, update);
            farmTopcorns(account);
        } else {
            s.a[account].lastSop = s.r.start;
            s.a[account].lastRain = 0;
        }
        if (grownStalk > 0) LibSilo.incrementBalanceOfStalk(account, grownStalk);
        s.a[account].lastUpdate = season();
        emit LastUpdate(account, s.a[account].lastUpdate, grownStalk);
    }

    function farmTopcorns(address account) private {
        uint256 accountStalk = s.a[account].s.stalk;
        uint256 topcorns = balanceOfFarmableTopcornsV3(account, accountStalk);
        if (topcorns > 0) {
            s.s.topcorns = s.s.topcorns - topcorns;
            uint256 seeds = topcorns * C.getSeedsPerTopcorn();
            Account.State storage a = s.a[account];
            s.a[account].s.seeds = a.s.seeds + seeds;
            s.a[account].s.stalk = accountStalk + (topcorns * C.getStalkPerTopcorn());
            LibTopcornSilo.addTopcornDeposit(account, season(), topcorns);
        }
    }

    function farmSops(address account, uint32 update) internal {
        if (s.sop.last > update || s.sops[s.a[account].lastRain] > 0) {
            s.a[account].sop.base = balanceOfPlentyBase(account);
            s.a[account].lastSop = s.sop.last;
        }
        if (s.r.raining) {
            if (s.r.start > update) {
                s.a[account].lastRain = s.r.start;
                s.a[account].sop.roots = s.a[account].roots;
            }
            if (s.sop.last == s.r.start) s.a[account].sop.basePerRoot = s.sops[s.sop.last];
        } else if (s.a[account].lastRain > 0) {
            s.a[account].lastRain = 0;
        }
    }

    // Variation of Open Zeppelins reentrant guard.
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
    modifier siloNonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        updateSilo(msg.sender);
        _;
        _status = _NOT_ENTERED;
    }

    modifier silo() {
        updateSilo(msg.sender);
        _;
    }
}