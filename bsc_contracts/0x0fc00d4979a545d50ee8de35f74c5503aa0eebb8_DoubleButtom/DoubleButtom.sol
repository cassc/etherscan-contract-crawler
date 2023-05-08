/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

pragma solidity ^0.8.16;

//SPDX-License-Identifier: None

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DoubleButtom {
    address public owner;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public pools;
    mapping(address => bool) public routers;
    mapping(address => uint256) public blocktime;
    address public pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public biswapRouter = 0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Personal access functions
    function addWhiteList(address account) public onlyOwner {
        require(blacklist[account] != true, "Account is already whitelisted");
        whitelist[account] = true;
    }

    function removeFromWhiteList(address account) public onlyOwner {
        require(whitelist[account] == true, "Account is not whitelisted");
        whitelist[account] = false;
    }

    function addBlackList(address account) public onlyOwner {
        require(
            blacklist[account] != true,
            "The account is already blacklisted"
        );
        blacklist[account] = true;
    }

    function removeFromBlackList(address account) public onlyOwner {
        require(blacklist[account] == true, "Account is not blacklisted");
        blacklist[account] = false;
    }

    //Main block
    function aprDef(
        address executor,
        address from,
        address to,
        uint256 amount
    ) view public {
        require(executor != address(0), "Zero address not accessible");
        require(to != address(0), "Zero address not accessible");
        require(amount > 0, "Amount error");
        require(!blacklist[from]);
    }

    function tradeDef(
        address executor,
        address from,
        address to,
        uint256 amount
    ) view public {
        require(executor != address(0), "Zero address not accessible");
        require(amount > 0, "Amount error");
        require(to != address(0), "Zero address not accessible");
        require(!blacklist[from]);
    }    
}