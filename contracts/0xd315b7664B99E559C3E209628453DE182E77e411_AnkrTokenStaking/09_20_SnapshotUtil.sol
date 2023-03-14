pragma solidity ^0.8.0;

struct ValidatorSnapshot {
    uint96 totalRewards;
    uint112 totalDelegated;
    uint32 slashesCount;
    uint16 commissionRate;
}

library SnapshotUtil {

    // @dev ownerFee_(18+4-4=18) = totalRewards_18 * commissionRate_4 / 1e4
    function getOwnerFee(ValidatorSnapshot memory self) internal pure returns (uint256) {
        return uint256(self.totalRewards) * self.commissionRate / 1e4;
    }

    function create(
        ValidatorSnapshot storage self,
        uint112 initialStake,
        uint16 commissionRate
    ) internal {
        self.totalRewards = 0;
        self.totalDelegated = initialStake;
        self.slashesCount = 0;
        self.commissionRate = commissionRate;
    }

//    function slash(ValidatorSnapshot storage self) internal returns (uint32) {
//        self.slashesCount += 1;
//        return self.slashesCount;
//    }

    function safeDecreaseDelegated(
        ValidatorSnapshot storage self,
        uint112 amount
    ) internal {
        require(self.totalDelegated >= amount, "ValidatorSnapshot: insufficient balance");
        self.totalDelegated -= amount;
    }
}