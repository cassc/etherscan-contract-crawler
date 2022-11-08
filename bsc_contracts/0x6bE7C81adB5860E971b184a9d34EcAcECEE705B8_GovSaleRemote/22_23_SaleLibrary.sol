// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SaleLibrary {
    function calcPercent2Decimal(uint256 _a, uint256 _b) internal pure returns(uint256) {
        return (_a * _b) / 1e4;
    }

    function calcAllocFromKom(uint256 _staked, uint256 _totalStaked, uint256 _sale) internal pure returns(uint256){
        return (((_staked * 1e8) / _totalStaked) * _sale) / 1e8;
    }

    function calcTokenReceived(uint256 _amountIn, uint256 _price) internal pure returns(uint256){
        return (_amountIn * 1e18) / _price;
    }

    function calcAmountIn(uint256 _received, uint256 _price) internal pure returns(uint256){
        return (_received * _price) / 1e18;
    }

    function calcWhitelist6Decimal(uint256 _allocation) internal pure returns(uint256){
        return (_allocation * 1e18) / 1e6;
    }
}