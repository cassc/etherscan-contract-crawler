// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

library IterableMapping {
   

    struct holder {
        address[] keys;
        mapping(address => uint256) balance;
        mapping(address => uint256) indexOf;
    }


    function updateBalance(
        holder storage map,
        address key,
        uint256 balance
    ) external {
        if (map.indexOf[key] == 0) {
            if (map.keys.length == 0 || map.keys[0] != key) {
                map.indexOf[key] = map.keys.length;
                map.keys.push(key);
            }
        }
        map.balance[key] = balance;
    }


    function getBalanceOf(holder storage map, address key)
        external
        view
        returns (uint256)
    {
        return map.balance[key];
    }

    function getKeyAddressAtIndex(holder storage map, uint256 index)
        external
        view
        returns (address)
    {
        return map.keys[index];
    }

    function holderSize(holder storage map) external view returns (uint256) {
        return map.keys.length;
    }
}