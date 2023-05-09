/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000 * 10 ** 18;
    string public name = "Airdoge";
    string public symbol = "AIRDOGE";
    uint public decimals = 18;
    address public owner;
    bool public contractBlocked;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    event Mint(address indexed to, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(!contractBlocked, "Contract is blocked.");
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(!contractBlocked, "Contract is blocked.");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function setBlocked(bool _blocked) public {
        require(msg.sender == owner, "Only contract owner can set blocked status.");
        contractBlocked = _blocked;
    }
    
    function blockTransactions() public {
        require(msg.sender == owner, "Only contract owner can block transactions.");
        contractBlocked = true;
    }
    
    function unblockTransactions() public {
        require(msg.sender == owner, "Only contract owner can unblock transactions.");
        contractBlocked = false;
    }
    
    function burn(uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }
    
    function mint(address to, uint value) public returns(bool) {
        require(msg.sender == owner, "Only contract owner can mint tokens.");
        balances[to] += value;
        totalSupply += value;
        emit Mint(to, value);
        return true;
    }
}