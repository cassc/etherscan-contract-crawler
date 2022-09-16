// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBrawlerBearzEvents} from "./IBrawlerBearzEvents.sol";
import {IBrawlerBearzErrors} from "./IBrawlerBearzErrors.sol";

interface IBrawlerBearzStake is IBrawlerBearzEvents, IBrawlerBearzErrors {
    struct Stake {
        address owner;
        uint96 stakedAt;
    }

    function stake(uint256[] calldata tokenIds) external;

    function unstake(uint256[] calldata tokenIds) external;
}