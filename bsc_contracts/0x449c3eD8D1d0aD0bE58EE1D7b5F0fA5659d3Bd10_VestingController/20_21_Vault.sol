// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import '@openzeppelin/contracts/finance/VestingWallet.sol';

contract Vault is VestingWallet {
    uint32 public immutable tgeFraction;
    uint32 public immutable tgeDenominator;
    uint32 public immutable vestingPeriodCount;
    uint32 public immutable vestingPeriodDurationSeconds;

    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint32 tgeFraction_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_
    ) VestingWallet(beneficiaryAddress, startTimestamp, vestingPeriodCount_ * vestingPeriodDurationSeconds_) {
        require(tgeFraction_ <= tgeDenominator_, 'tgeFraction_ can not be greater than tgeDenominator_');
        tgeFraction = tgeFraction_;
        tgeDenominator = tgeDenominator_;
        vestingPeriodCount = vestingPeriodCount_;
        vestingPeriodDurationSeconds = vestingPeriodDurationSeconds_;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view override returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            uint256 tgeAmount = (totalAllocation * tgeFraction) / tgeDenominator;
            uint256 totalVestedAmount = totalAllocation - tgeAmount;
            uint256 timeSinceStart = block.timestamp - start();
            uint256 periodsSinceStart = timeSinceStart / vestingPeriodDurationSeconds;
            if (tgeFraction == 0) {
                periodsSinceStart = periodsSinceStart + 1;
            }
            return tgeAmount + (totalVestedAmount * periodsSinceStart) / vestingPeriodCount;
        }
    }
}