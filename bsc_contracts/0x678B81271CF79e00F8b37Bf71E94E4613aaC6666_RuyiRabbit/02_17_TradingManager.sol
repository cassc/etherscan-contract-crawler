// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract TradingManager is Ownable {
    uint8 public tradeState;
    function inTrading() public view returns(bool) {
        return tradeState >= 2;
    }
    function inLiquidity() public view returns(bool) {
        return tradeState >= 1;
    }
    function setTradeState(uint8 s) public onlyOwner {
        tradeState = s;
    }
}