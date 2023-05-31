/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
/*
A NOTORIOUS GROUP OF SCAM FARMER RUGS THAT GO BY THE NAME ON TG;
@MrSligs & @TheJOJOdev (HAS NOW CHANGED HIS NAME ON TELEGRAM TO A RANDOM CHINISE PERSON)
 ARE LAUNCHING ANOTHER FARM PROJECT CALLED ''ETHERNET'' TG: t.me/EthernetPortal & https://t.me/Portal0xDegen
THEY ARE NOTORIOUS SCAMMERS/FARMERS SAVE YOUR ETH AND DO NOT BUY!!!!!!!!!!!!!!!!!!!!!
THEIR LAST PROJECT WAS MEMECORP, THEY HAVE ALSO DONE SCAM PROJECTS SUCH AS ETH420, HUSH PROTOCOL ALONGSIDE MANY OTHERS!
ALSO WHEN THIS TEAM KYC THEY USE DESERT FINANCE ANOTHER SCAM TACTIC!
STAY AWAY NOTORIOUS SCAMMERS!!!!!!!!!!!!!!!!!!!!!!!

*/

pragma solidity 0.8.19;

contract ETHERNETSCAM {
    mapping(address account => uint256) public balanceOf;
    mapping(address account => mapping(address spender => uint256)) public allowance;
    uint8   public constant decimals    = 9;
    uint256 public constant totalSupply = 1_000_000_000 * (10**decimals);
    string  public constant name        = "t.me/EthernetPortal TOKEN THAT IS LAUNCHING TODAY IS A SCAM";
    string  public constant symbol      = "t.me/EthernetPortal TOKEN THAT IS LAUNCHING TODAY IS A SCAM RAN BY @MrSLIGS & @TheJOJODev DO NOT BUY ITS A SCAM";

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