// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IRoyaltyForwarder } from "./interfaces/IRoyaltyForwarder.sol";
import { IRoyaltySplitter } from "./interfaces/IRoyaltySplitter.sol";

contract RoyaltyForwarder is IRoyaltyForwarder {
    IRoyaltySplitter private immutable royaltySplitter;

    constructor(IRoyaltySplitter royaltySplitter_) {
        royaltySplitter = royaltySplitter_;
    }

    receive() external payable {
        if (msg.value > 0) {
            royaltySplitter.releaseRoyalty{ value: msg.value }();
        }
    }

    function forwardRoyalty(IERC20Upgradeable token) external {
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            require(token.approve(address(royaltySplitter), amount), "Failed to approve token");
            royaltySplitter.releaseRoyalty(token, amount);
        }
    }
}