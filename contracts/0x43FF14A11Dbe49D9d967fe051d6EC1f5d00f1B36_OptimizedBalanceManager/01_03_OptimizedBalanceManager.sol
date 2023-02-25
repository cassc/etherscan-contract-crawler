// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { INTERNAL_DENOMINATOR } from "../libraries/Maths.sol";

import "hardhat/console.sol";

struct BalanceStore {
    mapping(address => uint256) lastUpdatedTime;
    mapping(uint256 => uint256) p;
    mapping(address => uint256) b;
    mapping(address => uint256) r;
    uint256 counter;
    uint256 ts;
    uint256 tr;
}

library OptimizedBalanceManager {
    function getBalance(BalanceStore storage store, address account) public view returns (uint256) {
        if (store.lastUpdatedTime[account] > store.counter || store.lastUpdatedTime[account] == 0)
            return store.b[account];
        return (store.b[account] * store.p[store.counter]) / store.p[store.lastUpdatedTime[account] - 1];
    }

    function getCacheReward(BalanceStore storage store, address account) public view returns (uint256) {
        return store.r[account] + (store.b[account] - getBalance(store, account));
    }

    function getTotalCacheReward(BalanceStore storage store) public view returns (uint256) {
        return store.tr;
    }

    function multiplyAll(BalanceStore storage store, uint256 mul) public {
        store.counter++;
        if (store.counter == 1) {
            store.p[0] = INTERNAL_DENOMINATOR;
        }
        store.p[store.counter] = (store.p[store.counter - 1] * mul) / INTERNAL_DENOMINATOR;
        uint256 newTs = (store.ts * mul) / INTERNAL_DENOMINATOR;
        store.tr += store.ts - newTs;
        store.ts = newTs;
    }

    function mint(
        BalanceStore storage store,
        address account,
        uint256 amount
    ) public {
        require(account != address(0), "mint to the zero address");

        store.ts += amount;
        store.r[account] = getCacheReward(store, account);
        store.b[account] = getBalance(store, account) + amount;
        store.lastUpdatedTime[account] = store.counter + 1;
    }

    function burn(
        BalanceStore storage store,
        address account,
        uint256 amount
    ) public {
        require(account != address(0), "burn from the zero address");

        uint256 orgBalance = getBalance(store, account);
        require(orgBalance >= amount, "burn amount exceeds balance");
        store.ts -= amount;
        store.r[account] = getCacheReward(store, account);
        store.b[account] = getBalance(store, account) - amount;
        store.lastUpdatedTime[account] = store.counter + 1;
    }

    function releaseCacheReward(BalanceStore storage store, address account) public returns (uint256 amount) {
        store.r[account] = getCacheReward(store, account);
        store.b[account] = getBalance(store, account);
        store.lastUpdatedTime[account] = store.counter + 1;
        amount = store.r[account];
        store.r[account] = 0;
        store.tr -= amount;
    }

    function totalSupply(BalanceStore storage store) public view returns (uint256) {
        return store.ts;
    }
}