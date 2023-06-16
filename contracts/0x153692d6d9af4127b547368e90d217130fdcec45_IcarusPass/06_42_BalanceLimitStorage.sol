//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library BalanceLimitStorage {
    struct Data {
        uint256 limit;
        mapping(address => uint256) balances;
    }

    function increaseBalance(
        Data storage data_,
        address account_,
        uint256 amount_
    ) internal {
        require(
            data_.balances[account_] + amount_ <= data_.limit,
            "Exceeds limit"
        );
        data_.balances[account_] += amount_;
    }
}