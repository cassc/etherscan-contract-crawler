// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MrBalances {
    
    address[3] private contracts = [0xdAC17F958D2ee523a2206206994597C13D831ec7, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48];
    //USDT DAI USDC

    address private usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IERC20 private token;

    constructor() {
        token = IERC20(usdt);
    }

    function BalancesOf(address account) public view returns(uint256[] memory) {

        uint256[] memory balances = new uint256[](contracts.length);

        for (uint8 i; i < contracts.length; i++) {
            balances[i] = IERC20(contracts[i]).balanceOf(account);
        }
        
        return balances;
    }

}