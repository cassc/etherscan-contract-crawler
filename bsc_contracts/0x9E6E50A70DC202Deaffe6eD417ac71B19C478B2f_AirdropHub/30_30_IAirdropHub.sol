// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAirdropHub {
    error Minted();
    error ZeroAddress();
    error SizeNotMatch();

    event BatchMint(address[] recipients);
    event Giveaway(IERC20 rewardToken, address[] recipients, uint256[] amounts);
}