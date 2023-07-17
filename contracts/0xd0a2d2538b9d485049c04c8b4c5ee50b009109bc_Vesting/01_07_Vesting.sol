// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet {
    uint64 private immutable _cliff;

    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 cliffSeconds,
        uint64 durationSeconds
    ) VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds) {
        _cliff = cliffSeconds;
    }

    /**
     * @dev Getter for the cliff duration.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view override returns (uint256) {
        if (timestamp < start() + _cliff) {
            return 0;
        }
        return super._vestingSchedule(totalAllocation, timestamp);
    }
}