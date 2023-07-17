// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

contract Vesting is VestingWalletUpgradeable {
    function initialize(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) external initializer {
        __VestingWallet_init(beneficiaryAddress, startTimestamp, durationSeconds);
    }
}