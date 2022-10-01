/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./LPSilo.sol";

/**
 * @title TopCorn Silo
 **/
contract TopcornSilo is LPSilo {
    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);
    event TopcornRemove(address indexed account, uint32[] crates, uint256[] crateTopcorns, uint256 topcorns, uint256 stalkRemoved, uint256 seedsRemoved);
    event TopcornWithdraw(address indexed account, uint256 season, uint256 topcorns);

    /**
     * Getters
     **/

    function totalDepositedTopcorns() external view returns (uint256) {
        return s.topcorn.deposited;
    }

    function totalWithdrawnTopcorns() external view returns (uint256) {
        return s.topcorn.withdrawn;
    }

    function topcornDeposit(address account, uint32 id) public view returns (uint256) {
        return s.a[account].topcorn.deposits[id];
    }

    function topcornWithdrawal(address account, uint32 i) external view returns (uint256) {
        return s.a[account].topcorn.withdrawals[i];
    }

    /**
     * Internal
     **/

    function _depositTopcorns(uint256 amount) internal {
        require(amount > 0, "Silo: No topcorns.");
        LibTopcornSilo.incrementDepositedTopcorns(amount);
        LibSilo.depositSiloAssets(msg.sender, amount * C.getSeedsPerTopcorn(), amount * C.getStalkPerTopcorn());
        LibTopcornSilo.addTopcornDeposit(msg.sender, season(), amount);
    }

    function _withdrawTopcorns(uint32[] calldata crates, uint256[] calldata amounts) internal {
        require(crates.length == amounts.length, "Silo: Crates, amounts are diff lengths.");
        (uint256 topcornsRemoved, uint256 stalkRemoved, uint256 seedsRemoved) = removeTopcornDeposits(crates, amounts);
        addTopcornWithdrawal(msg.sender, season() + s.season.withdrawSeasons, topcornsRemoved);
        LibTopcornSilo.decrementDepositedTopcorns(topcornsRemoved);
        LibSilo.withdrawSiloAssets(msg.sender, seedsRemoved, stalkRemoved);
        LibSilo.updateBalanceOfRainStalk(msg.sender);
        LibCheck.topcornBalanceCheck();
    }

    function removeTopcornDeposits(uint32[] calldata crates, uint256[] calldata amounts) private returns (uint256 topcornsRemoved, uint256 stalkRemoved, uint256 seedsRemoved) {
        for (uint256 i; i < crates.length; i++) {
            uint256 crateTopcorns = LibTopcornSilo.removeTopcornDeposit(msg.sender, crates[i], amounts[i]);
            topcornsRemoved = topcornsRemoved + crateTopcorns;
            stalkRemoved = stalkRemoved + (crateTopcorns * C.getStalkPerTopcorn() + (LibSilo.stalkReward(crateTopcorns * C.getSeedsPerTopcorn(), season() - crates[i])));
        }
        seedsRemoved = topcornsRemoved * C.getSeedsPerTopcorn();
        emit TopcornRemove(msg.sender, crates, amounts, topcornsRemoved, stalkRemoved, seedsRemoved);
    }

    function addTopcornWithdrawal(
        address account,
        uint32 arrivalSeason,
        uint256 amount
    ) private {
        s.a[account].topcorn.withdrawals[arrivalSeason] = s.a[account].topcorn.withdrawals[arrivalSeason] + amount;
        s.topcorn.withdrawn = s.topcorn.withdrawn + amount;
        emit TopcornWithdraw(msg.sender, arrivalSeason, amount);
    }

    function topcorn() internal view returns (ITopcorn) {
        return ITopcorn(s.c.topcorn);
    }
}