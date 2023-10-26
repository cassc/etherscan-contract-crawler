/**
 *Submitted for verification at Etherscan.io on 2023-09-20
*/

// SPDX-License-Identifier: MIT
/**

https://t.me/WojakRussianRoulette 
https://twitter.com/Wojak_RR
https://wojakrussianroulette.io/ 

Step into the world of risk & reward where fortunes can change with the pull of a trigger. 

Hold $VODKA, join the game, spin the barrel and... win or 🧠 🔫

**/
pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WojakRussianRoulette is IERC20{
    

    function name() public pure returns (string memory) {
        return "Wojak Russian Roulette";
    }

    function symbol() public pure returns (string memory) {
        return "VODKA";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure override returns (uint256) {
        return 1000000;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function allowance(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}