//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./BaseErc20Light.sol";

contract PepeLito is BaseErc20Light {

    uint256 immutable public mhAmount;

    constructor () {
        configure(0x71acdBF02BC5D0f0aa844aFb399E2C4306931D97);

        symbol = "PELITO";
        name = "PEPELITO";
        decimals = 18;

        // Max Hold
        mhAmount = 4_500_000_000_000  * 10 ** decimals;

        // Finalise
        _totalSupply = _totalSupply + (420_690_000_000_000  * 10 ** decimals);
        _balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // Overrides

    function preTransfer(address from, address to, uint256 value) override internal {
        if (launched && 
            from != owner && to != owner && 
            exchanges[to] == false
        ) {
            require (_balances[to] + value <= mhAmount, "this is over the max hold amount");
        }
        
        super.preTransfer(from, to, value);
    }
} 