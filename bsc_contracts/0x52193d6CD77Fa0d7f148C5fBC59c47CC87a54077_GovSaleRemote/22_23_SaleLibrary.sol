// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SaleLibrary {
    function calcPercent2Decimal(uint128 _a, uint128 _b) internal pure returns(uint128) {
        return (_a * _b) / 1e4;
    }

    function calcAllocFromKom(uint128 _staked, uint128 _totalStaked, uint128 _sale) internal pure returns(uint128){
        return (((_staked * 1e8) / _totalStaked) * _sale) / 1e8;
    }

    function calcTokenReceived(uint128 _amountIn, uint128 _price) internal pure returns(uint128){
        return (_amountIn * 1e18) / _price;
    }

    function calcAmountIn(uint128 _received, uint128 _price) internal pure returns(uint128){
        return (_received * _price) / 1e18;
    }

    function calcWhitelist6Decimal(uint128 _allocation) internal pure returns(uint128){
        return (_allocation * 1e18) / 1e6;
    }

}