/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20 {
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Smitty Werben Man Jensen";
    string public symbol = "SMTY";
    uint8 public decimals = 18;
    uint public totalSupply = 1111111111 * (10 ** decimals);
    address public owner;

    constructor(){
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner{
        require(msg.sender == owner,"NOT AUTHORIZED!");
        _;
    }

    function transfer(address recipient, uint amount) external returns (bool) {

        require(balanceOf[msg.sender] >= amount,"NOT ENOUGH TOKENS!");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {

        require(allowance[sender][msg.sender] >= amount, "APPROVAL NEEDED !");
        require(balanceOf[sender] >= amount,"NOT ENOUGH TOKENS!" );
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

}