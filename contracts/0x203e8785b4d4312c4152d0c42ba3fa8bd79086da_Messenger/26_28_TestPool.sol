// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Pool} from "../Pool.sol";
import {RewardManager} from "../RewardManager.sol";

contract TestPool is Pool {
    constructor(
        address router_,
        uint a_,
        ERC20 token_,
        uint16 feeShareBP_,
        uint balanceRatioMinBP_
    ) Pool(router_, a_, token_, feeShareBP_, balanceRatioMinBP_, "LP", "LP") {}

    function setVUsdBalance(uint vUsdBalance_) public {
        vUsdBalance = vUsdBalance_;
    }

    function setTokenBalance(uint tokenBalance_) public {
        tokenBalance = tokenBalance_;
    }
}