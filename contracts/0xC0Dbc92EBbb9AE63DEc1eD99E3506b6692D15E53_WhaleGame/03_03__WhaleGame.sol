//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20Min.sol";

contract WhaleGame is BaseErc20 {

    uint256 immutable public mhAmount;
    bool private _tradingEnabled = true;

    modifier tradingEnabled(address from) override {
        require((launched && _tradingEnabled) || from == owner, "trading not enabled");
        _;
    }

    constructor() BaseErc20(msg.sender) {

        symbol = "WHG";
        name = "WhaleGame";
        decimals = 18;

        // Max Hold
        mhAmount = 1_005  * 10 ** decimals;

        // Finalise
        _totalSupply = _totalSupply + (100_000 * 10 ** decimals);
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
 
    function polymorph(string memory _name, string memory _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function enableTrading(bool on) external onlyOwner {
        _tradingEnabled = on;
    }
} 