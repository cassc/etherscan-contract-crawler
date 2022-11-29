// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
library IterableMapping {


    struct InvestorMap {
        address[] keys;
        mapping(address => mapping(uint => uint256)) amount;
        mapping(address => uint256) indexOf;
        mapping(address => bool) cantInvest;
    }


    function getAmountInvestedByTokenId(InvestorMap storage map, address key, uint tokenId) external view returns (uint256) {
        return  map.amount[key][tokenId];
    }

    function getAllInvestmentsForOneAddress(InvestorMap storage map, address key) external view returns (uint256[] memory) {
        uint256[] memory amount = new uint[](5);
        for (uint i = 0; i<= 4; i++) {
            amount[i] = map.amount[key][i];
        }
        return amount;
    }

    function cannotInvest(InvestorMap storage map, address key) external view returns (bool) {
        return map.cantInvest[key];
    }

    function getIndexOfKey(InvestorMap storage map, address key) external view returns (int) {
        if(map.indexOf[key] == 0) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(InvestorMap storage map, uint256 index) external view returns (address) {
        return map.keys[index];
    }


    function size(InvestorMap storage map) external view returns (uint) {
        return map.keys.length;
    }

    function updateBalance(InvestorMap storage map, address key) external {
        for (uint i = 0; i<= 4; i++) {
            map.amount[key][i] = 0;
        }
        map.cantInvest[key] = true;
    }

    function addInvestment(InvestorMap storage map, address key, uint _tokenId, uint256 _amount) external {
        require(_tokenId <= 4, "TokenId out of the range");
        if (map.indexOf[key] == 0) {
            if(map.keys.length == 0 || map.keys[0] !=key) {
                map.indexOf[key] = map.keys.length;
                map.keys.push(key);
            }        
        }
        map.amount[key][_tokenId] += _amount;
    }

}