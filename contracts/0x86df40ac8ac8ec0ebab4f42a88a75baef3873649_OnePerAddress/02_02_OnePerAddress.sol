// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITokenGuard} from "./ITokenGuard.sol";

// Enforces that one address can own one of a token at a time.
// Often used for identity and reputational use cases.
// Guard called after token transfer state change made through _afterTokenTransfer hook.
// Supports all of erc20, erc721, and erc1155 standards.
contract OnePerAddress is ITokenGuard {
    // erc20 & erc721
    function isAllowed(address, address, address to, uint256) external returns (bool) {
        return ITokenBalance(msg.sender).balanceOf(to) < 2;
    }

    // erc1155
    function isAllowed(address, address, address to, uint256[] memory ids, uint256[] memory) external returns (bool) {
        uint256 len = ids.length;
        for (uint256 i; i < len; i++) {
            if (ITokenBalance(msg.sender).balanceOf(to, ids[i]) > 1) return false;
        }
        return true;
    }
}

interface ITokenBalance {
    // erc20 & erc721
    function balanceOf(address account) external returns (uint256);
    // erc1155
    function balanceOf(address account, uint256 id) external returns (uint256);
}