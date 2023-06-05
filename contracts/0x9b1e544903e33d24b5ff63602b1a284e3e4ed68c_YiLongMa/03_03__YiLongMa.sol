//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20Min.sol";

contract YiLongMa is BaseErc20 {

    uint256 immutable public mhAmount;

    constructor() BaseErc20(msg.sender) {

        symbol = "YILONG";
        name = "YiLongMa";
        decimals = 9;

        // Max Hold
        mhAmount = 2_000_000_000_005  * 10 ** decimals;

        // Finalise
        _totalSupply = _totalSupply + (100_000_000_000_000 * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // Overrides


    function preTransfer(address from, address to, uint256 value) override internal {      
        if (launched && 
            from != owner && to != owner && 
            exchanges[to] == false && 
            to != getRouterAddress()
        ) {
            require (_balances[to] + value <= mhAmount, "this is over the max hold amount");
        }
        
        super.preTransfer(from, to, value);
    }
} 