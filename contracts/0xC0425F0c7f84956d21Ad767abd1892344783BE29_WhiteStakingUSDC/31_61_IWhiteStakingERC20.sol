// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWhiteStaking {    
    event Claim(address indexed acount, uint amount);
    event Profit(uint amount);

    function claimProfit() external returns (uint profit);
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function profitOf(address account) external view returns (uint);
}

interface IWhiteStakingERC20 {
    function sendProfit(uint amount) external;
}