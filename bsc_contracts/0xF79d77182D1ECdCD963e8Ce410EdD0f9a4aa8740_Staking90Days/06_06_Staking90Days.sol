// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Staking.sol";

contract Staking90Days is Staking {
    uint32 constant MATURATION_DAYS = 90; // 90 days
    uint32 constant STARTING_BURN_RATE = 20_000; // 20% starting burn rate
    uint32 constant REWARD_RATE = 16_027; // 65% reward / 365 days = 16.027% reward / 90 days
    uint32 constant STAKING_FEE_RATE = 2_500; // 2.5% staking fee
    constructor(address _tokenAddress) Staking(_tokenAddress, MATURATION_DAYS, STARTING_BURN_RATE, REWARD_RATE, STAKING_FEE_RATE) {}
}