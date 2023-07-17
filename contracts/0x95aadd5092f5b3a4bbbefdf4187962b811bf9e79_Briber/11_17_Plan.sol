// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IBribe} from "../interfaces/IBribe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Plan {
    IBribe hhBriber;
    address gauge;
    IERC20 token;
    uint256 amount;
    uint256 interval;
    uint256 nextExec;
    uint256 createdAt;
    uint256 remainingEpochs;
    bool canSkip;
    bool isFixed;
}