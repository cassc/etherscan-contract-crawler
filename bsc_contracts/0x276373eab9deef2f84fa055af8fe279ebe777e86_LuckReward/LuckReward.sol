/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface IBEP20 
{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}

contract LuckReward
{

    mapping(address => uint) public users;

    address public owner;

    address public _reward_token = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IBEP20 tokenContract;

    constructor(){
        owner = msg.sender;
        tokenContract = IBEP20(0x5F8203DFBBE6F883C54F68eeaeF4Ef6f706bA083);
    }
    
    function deposit(uint _amount) external {
    tokenContract.approve(msg.sender, _amount);
    tokenContract.transferFrom(msg.sender, address(this), _amount);
    }

    function totalToken() public view returns(uint)
    {
     return tokenContract.balanceOf(address(this)) ; 
    }
    
}