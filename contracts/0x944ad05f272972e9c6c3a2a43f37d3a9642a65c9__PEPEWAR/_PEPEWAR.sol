/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

// SPDX-License-Identifier: MIT

/*
PEPE's WAR: Join the battle and rank up !

Get ready for an epic battle between Pepe's Army and the intellectual MemeLord! In this war-torn landscape, a revolutionary crypto token emerges - the mighty PEPE token. It aims to dominate and reshape the fate of Memelandia!

0% tax token

Telegram: https://t.me/PepeWarCamp

Website: https://www.pepeswar.top/

Twitter: https://twitter.com/PepeWarERC
*/

pragma solidity >=0.8.12 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract $PEPEWAR is IERC20 {
    string public constant name = "PEPEWAR";
    string public constant symbol = "$PEPEWAR";
    uint256 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000_000 * 10 ** decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (allowance[from][msg.sender] < type(uint).max) {
            allowance[from][msg.sender] -= amount;
        }
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}