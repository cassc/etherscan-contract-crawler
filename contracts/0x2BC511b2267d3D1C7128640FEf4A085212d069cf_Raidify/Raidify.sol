/**
 *Submitted for verification at Etherscan.io on 2023-04-23
*/

// SPDX-License-Identifier: MIT
/**

🔘 Elevate Your Raiding Strategy with Raidify 🔘

JOIN NOW: https://t.me/Raidify 
Website - Link in TG
Raid Bot - Live today

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


contract Raidify is IERC20{
    

    function name() public pure returns (string memory) {
        return "Raidify";
    }

    function symbol() public pure returns (string memory) {
        return "RAIDIFY";
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