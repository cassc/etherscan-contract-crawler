// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vault is Ownable, VestingWallet {
    uint32 public immutable tgeFraction;
    uint32 public immutable tgeDenominator;
    uint32 public immutable vestingPeriodCount;
    uint32 public immutable vestingPeriodDurationSeconds;

    address private __beneficiary;

    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint32 tgeFraction_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_
    ) VestingWallet(beneficiaryAddress, startTimestamp, vestingPeriodCount_ * vestingPeriodDurationSeconds_) {
        require(tgeFraction_ <= tgeDenominator_, "tgeFraction_ can not be greater than tgeDenominator_");

        __beneficiary = beneficiaryAddress;
        tgeFraction = tgeFraction_;
        tgeDenominator = tgeDenominator_;
        vestingPeriodCount = vestingPeriodCount_;
        vestingPeriodDurationSeconds = vestingPeriodDurationSeconds_;
    }

    function beneficiary() public view override returns (address) {
        return __beneficiary;
    }

    function changeBeneficiary(address beneficiaryAddress) external onlyOwner {
        require(beneficiaryAddress != address(0), "Vault: beneficiary is zero address");
        require(beneficiaryAddress != __beneficiary, "Vault: new beneficiary is the same as the old one");

        __beneficiary = beneficiaryAddress;
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view override returns (uint256) {
        if (timestamp < start()) return 0;

        if (timestamp > start() + duration()) return totalAllocation;

        uint256 tgeAmount = (totalAllocation * tgeFraction) / tgeDenominator;
        uint256 totalVestedAmount = totalAllocation - tgeAmount;
        uint256 timeSinceStart = block.timestamp - start();
        uint256 periodsSinceStart = timeSinceStart / vestingPeriodDurationSeconds;

        if (tgeFraction == 0) periodsSinceStart = periodsSinceStart + 1;

        return tgeAmount + (totalVestedAmount * periodsSinceStart) / vestingPeriodCount;
    }
}