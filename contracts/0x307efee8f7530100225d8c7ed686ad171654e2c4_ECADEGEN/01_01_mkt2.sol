/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

// SPDX-License-Identifier: MIT
/*
If you are tired of scam projects, rugs, etc. You can refer to my chanel, where the projects are thoroughly tested. 
I'm also a professional sniper so I know what you need. follow me

 Telegram: https://t.me/EcaDegen
 Snipe Detector & Token burnt tracker https://t.me/TrackerETHBot
*/

pragma solidity 0.8.19;

contract ECADEGEN {
    mapping(address account => uint256) public balanceOf;
    mapping(address account => mapping(address spender => uint256)) public allowance;
    uint8   public constant decimals    = 9;
    uint256 public constant totalSupply = 100_000_000_000 * (10**decimals);
    string  public constant name        = "If you are tired of scam projects, rugs, etc. You can refer to my chanel, where the projects are thoroughly tested. I'm also a professional sniper so I know what you need. follow me";
    string  public constant symbol      = "t.me/EcaDegen";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(msg.sender != address(0) && spender != address(0), "ERC20: Zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount,"ERC20: amount exceeds allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "ERC20: Zero address");
        require(balanceOf[from] >= amount, "ERC20: amount exceeds balance");        
        balanceOf[from] -= amount;
        balanceOf[to]   += amount;
        emit Transfer(from, to, amount);
    }
}