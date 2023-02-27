// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../interfaces/ILevelManager.sol';
import '../AdminableUpgradeable.sol';

abstract contract WithLevels is AdminableUpgradeable, ILevelManager {
    string constant noneTierId = 'none';

    Tier[] public tiers;
    
    event TierUpdate(
        string indexed id,
        uint256 multiplier,
        uint256 lockingPeriod,
        uint256 minAmount,
        bool random,
        uint8 odds,
        bool vip,
        bool aag
    );
    event TierRemove(string indexed id, uint256 idx);

    function initializeNoneLevel() internal {
        // Init with none level
        tiers.push(Tier(noneTierId, 0, 0, 0, false, 0, false, false));
    }

    function getTierIds() external view override returns (string[] memory) {
        string[] memory ids = new string[](tiers.length);
        for (uint256 i = 0; i < tiers.length; i++) {
            ids[i] = tiers[i].id;
        }

        return ids;
    }

    function getTierById(string calldata id) public view override returns (Tier memory) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                return tiers[i];
            }
        }
        revert('No such tier');
    }

    function getTierIdxForAmount(uint256 amount, bool skipVip) internal view returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 maxTierK = 0;
        uint256 maxTierV;
        for (uint256 i = 1; i < tiers.length; i++) {
            Tier storage tier = tiers[i];
            if (tier.vip && skipVip) {
                continue;
            }
            if (amount >= tier.minAmount && tier.minAmount > maxTierV) {
                maxTierK = i;
                maxTierV = tier.minAmount;
            }
        }

        return maxTierK;
    }

    function setTier(
        string calldata id,
        uint256 multiplier,
        uint256 lockingPeriod,
        uint256 minAmount,
        bool random,
        uint8 odds,
        bool vip,
        bool aag
    ) external onlyOwnerOrAdmin returns (uint256) {
        require(!stringsEqual(id, noneTierId), "Can't change 'none' tier");

        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                tiers[i].multiplier = multiplier;
                tiers[i].lockingPeriod = lockingPeriod;
                tiers[i].minAmount = minAmount;
                tiers[i].random = random;
                tiers[i].odds = odds;
                tiers[i].vip = vip;
                tiers[i].aag = aag;

                emit TierUpdate(id, multiplier, lockingPeriod, minAmount, random, odds, vip, aag);

                return i;
            }
        }

        Tier memory newTier = Tier(id, multiplier, lockingPeriod, minAmount, random, odds, vip, aag);
        tiers.push(newTier);

        emit TierUpdate(id, multiplier, lockingPeriod, minAmount, random, odds, vip, aag);

        return tiers.length - 1;
    }

    function deleteTier(string calldata id) external onlyOwnerOrAdmin {
        require(!stringsEqual(id, noneTierId), "Can't delete 'none' tier");

        for (uint256 tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
            if (stringsEqual(tiers[tierIdx].id, id)) {
                for (uint256 i = tierIdx; i < tiers.length - 1; i++) {
                    tiers[i] = tiers[i + 1];
                }
                tiers.pop();

                emit TierRemove(id, tierIdx);
                break;
            }
        }
    }

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}