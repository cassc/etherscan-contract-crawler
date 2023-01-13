// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Excludes.sol";

abstract contract Limit is ERC20, Ownable, Excludes {
    bool internal isLimited;
    uint256 internal _LimitBuy;
    uint256 internal _LimitSell;
    uint256 internal _LimitHold;
    mapping(address => uint256) isBuyedAmount;
    function __Limit_init(uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) internal {
        setLimit(true, LimitBuy_, LimitSell_, LimitHold_);
    }
    function setLimit(bool isLimited_, uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) public onlyOwner {
        isLimited = isLimited_;
        _LimitBuy = LimitBuy_;
        _LimitSell = LimitSell_;
        _LimitHold = LimitHold_;
    }
    function checkLimitTokenBuy(address to, uint256 amount) internal {
        if (isLimited) {
            if (_LimitBuy>0) require(amount <= _LimitBuy, "exceeds of buy amount Limit");
            if (_LimitHold>0) {
                require(amount+isBuyedAmount[to] <= _LimitHold, "exceeds of hold amount Limit");
                isBuyedAmount[to] += amount;
            }
        }
    }
    function checkLimitTokenSell(uint256 amount) internal view {
        if (isLimited && _LimitSell>0) require(amount <= _LimitSell, "exceeds of sell amount Limit");
    }
    function removeLimit() internal {if (isLimited) isLimited = false;}
    function reuseLimit() internal {if (!isLimited) isLimited = true;}
}