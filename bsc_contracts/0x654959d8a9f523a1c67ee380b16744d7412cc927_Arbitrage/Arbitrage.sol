/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IExchange {
    function getExchangeRate(address inputToken, address outputToken, uint256 inputAmount) external view returns (uint256);
    function swapTokens(address inputToken, address outputToken, uint256 inputAmount, uint256 minOutput) external returns (uint256);
}

contract Arbitrage {
    address private owner;
    IExchange[] private exchanges;
    IERC20[] private tokens;

    constructor(address[] memory _exchanges, address[] memory _tokens) {
        owner = msg.sender;
        
        for (uint i = 0; i < _exchanges.length; i++) {
            exchanges.push(IExchange(_exchanges[i]));
        }
        
        for (uint i = 0; i < _tokens.length; i++) {
            tokens.push(IERC20(_tokens[i]));
        }
    }

    function getExchangeRate(uint256 exchange, uint256 inputTokenIndex, uint256 outputTokenIndex, uint256 inputAmount) private view returns (uint256) {
        return exchanges[exchange].getExchangeRate(address(tokens[inputTokenIndex]), address(tokens[outputTokenIndex]), inputAmount);
    }

    function performArbitrage(uint256 inputTokenIndex, uint256 outputTokenIndex, uint256 inputAmount, uint256 minProfit, uint256 maxSlippage, uint256 exchange1, uint256 exchange2) external {
        require(msg.sender == owner, "Unauthorized");
        
        uint256 outputAmount1 = getExchangeRate(exchange1, inputTokenIndex, outputTokenIndex, inputAmount);
        uint256 outputAmount2 = getExchangeRate(exchange2, inputTokenIndex, outputTokenIndex, inputAmount);
        
        uint256 totalInput = inputAmount;
        uint256 totalOutput = outputAmount1;
        
        if (outputAmount2 > outputAmount1) {
            totalOutput = outputAmount2;
            uint256 temp = exchange1;
            exchange1 = exchange2;
            exchange2 = temp;
        }
        
        require(totalOutput * (100 - maxSlippage) / 100 >= totalInput + minProfit, "Arbitrage opportunity not profitable");
        
        tokens[inputTokenIndex].approve(address(exchanges[exchange1]), inputAmount);
        exchanges[exchange1].swapTokens(address(tokens[inputTokenIndex]), address(tokens[outputTokenIndex]), inputAmount, totalOutput);
        tokens[outputTokenIndex].approve(address(exchanges[exchange2]), totalOutput);
        exchanges[exchange2].swapTokens(address(tokens[outputTokenIndex]), address(tokens[inputTokenIndex]), totalOutput, inputAmount);
        
        uint256 balance = tokens[inputTokenIndex].balanceOf(address(this));
        
        if (balance > 0) {
            tokens[inputTokenIndex].transfer(msg.sender, balance);
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Unauthorized");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}