// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRoyaltyForwarder {
    function forwardRoyalty(IERC20Upgradeable token) external;
}