/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.8.16;

import "./LibCheck.sol";
import "./LibInternal.sol";
import "./LibMarket.sol";
import "./LibAppStorage.sol";
import "../interfaces/IWBNB.sol";

/**
 * @title Claim Library handles claiming TopCorn and LP withdrawals, harvesting plots and claiming BNB.
 **/
library LibClaim {
    event TopcornClaim(address indexed account, uint32[] withdrawals, uint256 topcorns);
    event LPClaim(address indexed account, uint32[] withdrawals, uint256 lp);
    event BnbClaim(address indexed account, uint256 bnb);
    event Harvest(address indexed account, uint256[] plots, uint256 topcorns);
    event PodListingCancelled(address indexed account, uint256 indexed index);

    struct Claim {
        uint32[] topcornWithdrawals;
        uint32[] lpWithdrawals;
        uint256[] plots;
        bool claimBnb;
        bool convertLP;
        uint256 minTopcornAmount;
        uint256 minBNBAmount;
        bool toWallet;
    }

    function claim(Claim calldata c) public returns (uint256 topcornsClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (c.topcornWithdrawals.length > 0) topcornsClaimed = topcornsClaimed + claimTopcorns(c.topcornWithdrawals);
        if (c.plots.length > 0) topcornsClaimed = topcornsClaimed + harvest(c.plots);
        if (c.lpWithdrawals.length > 0) {
            if (c.convertLP) {
                if (!c.toWallet) topcornsClaimed = topcornsClaimed + removeClaimLPAndWrapTopcorns(c.lpWithdrawals, c.minTopcornAmount, c.minBNBAmount);
                else removeAndClaimLP(c.lpWithdrawals, c.minTopcornAmount, c.minBNBAmount);
            } else claimLP(c.lpWithdrawals);
        }
        if (c.claimBnb) claimBnb();

        if (topcornsClaimed > 0) {
            if (c.toWallet) ITopcorn(s.c.topcorn).transfer(msg.sender, topcornsClaimed);
            else s.a[msg.sender].wrappedTopcorns = s.a[msg.sender].wrappedTopcorns + topcornsClaimed;
        }
    }

    // Claim Topcorns

    function claimTopcorns(uint32[] calldata withdrawals) public returns (uint256 topcornsClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            topcornsClaimed = topcornsClaimed + claimTopcornWithdrawal(msg.sender, withdrawals[i]);
        }
        emit TopcornClaim(msg.sender, withdrawals, topcornsClaimed);
    }

    function claimTopcornWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].topcorn.withdrawals[_s];
        require(amount > 0, "Claim: TopCorn withdrawal is empty.");
        delete s.a[account].topcorn.withdrawals[_s];
        s.topcorn.withdrawn = s.topcorn.withdrawn - amount;
        return amount;
    }

    // Claim LP

    function claimLP(uint32[] calldata withdrawals) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimed = _claimLP(withdrawals);
        IPancakePair(s.c.pair).transfer(msg.sender, lpClaimed);
    }

    function removeAndClaimLP(
        uint32[] calldata withdrawals,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) public returns (uint256 topcorns) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (topcorns, ) = LibMarket.removeLiquidity(lpClaimd, minTopcornAmount, minBNBAmount);
    }

    function removeClaimLPAndWrapTopcorns(
        uint32[] calldata withdrawals,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) private returns (uint256 topcorns) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (topcorns, ) = LibMarket.removeLiquidityWithTopcornAllocation(lpClaimd, minTopcornAmount, minBNBAmount);
    }

    function _claimLP(uint32[] calldata withdrawals) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimd = 0;
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            lpClaimd = lpClaimd + claimLPWithdrawal(msg.sender, withdrawals[i]);
        }
        emit LPClaim(msg.sender, withdrawals, lpClaimd);
        return lpClaimd;
    }

    function claimLPWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].lp.withdrawals[_s];
        require(amount > 0, "Claim: LP withdrawal is empty.");
        delete s.a[account].lp.withdrawals[_s];
        s.lp.withdrawn = s.lp.withdrawn - amount;
        return amount;
    }

    // Season of Plenty

    function claimBnb() public {
        LibInternal.updateSilo(msg.sender);
        uint256 bnb = claimPlenty(msg.sender);
        emit BnbClaim(msg.sender, bnb);
    }

    function claimPlenty(address account) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.sop.base == 0) return 0;
        uint256 bnb = (s.a[account].sop.base * s.sop.wbnb) / s.sop.base;
        s.sop.wbnb = s.sop.wbnb - bnb;
        s.sop.base = s.sop.base - s.a[account].sop.base;
        s.a[account].sop.base = 0;
        IWBNB(s.c.wbnb).withdraw(bnb);
        (bool success, ) = account.call{value: bnb}("");
        require(success, "WBNB: bnb transfer failed");
        return bnb;
    }

    // Harvest

    function harvest(uint256[] calldata plots) public returns (uint256 topcornsHarvested) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < plots.length; i++) {
            require(plots[i] < s.f.harvestable, "Claim: Plot not harvestable.");
            require(s.a[msg.sender].field.plots[plots[i]] > 0, "Claim: Plot not harvestable.");
            uint256 harvested = harvestPlot(msg.sender, plots[i]);
            topcornsHarvested = topcornsHarvested + harvested;
        }
        require(s.f.harvestable - s.f.harvested >= topcornsHarvested, "Claim: Not enough Harvestable.");
        s.f.harvested = s.f.harvested + topcornsHarvested;
        emit Harvest(msg.sender, plots, topcornsHarvested);
    }

    function harvestPlot(address account, uint256 plotId) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 pods = s.a[account].field.plots[plotId];
        require(pods > 0, "Claim: Plot is empty.");
        uint256 harvestablePods = s.f.harvestable - plotId;
        delete s.a[account].field.plots[plotId];
        if (s.podListings[plotId] > 0) {
            cancelPodListing(plotId);
        }
        if (harvestablePods >= pods) return pods;
        s.a[account].field.plots[plotId + harvestablePods] = pods - harvestablePods;
        return harvestablePods;
    }

    function cancelPodListing(uint256 index) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.podListings[index];
        emit PodListingCancelled(msg.sender, index);
    }
}