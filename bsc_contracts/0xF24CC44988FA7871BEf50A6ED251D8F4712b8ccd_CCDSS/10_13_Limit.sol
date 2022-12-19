// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Excludes.sol";

abstract contract Limit is ERC20, Ownable, Excludes {
    uint256 internal _LimitBuy;
    uint256 internal _LimitSell;
    bool internal isLimited;
    mapping(address => uint256) isBuyedAmount;
    function __Limit_init(uint256 LimitBuy_, uint256 LimitSell_) internal {
        _LimitBuy = LimitBuy_;
        _LimitSell = LimitSell_;
        isLimited = true;
    }
    function checkLimitTokenBuy(address to, uint256 amount) internal {
        if (isLimited) {
            require(amount+isBuyedAmount[to] <= _LimitBuy, "exceeds of buy amount Limit");
            isBuyedAmount[to] += amount;
        }
    }
    function checkLimitTokenSell(uint256 amount) internal view {
        if (isLimited) require(amount <= _LimitSell, "exceeds of sell amount Limit");
    }
    function removeLimit() internal {if (isLimited) isLimited = false;}
}