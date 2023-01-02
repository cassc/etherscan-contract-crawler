/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => bool) public approvedAddresses;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Avatar INU";
    string public symbol = "AVI";
    uint public decimals = 18;
    bool public requireApproval = false;


    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function setRequireApproval(bool newValue) public {
        address owner = msg.sender;
        require(msg.sender == owner, 'only owner can set requireApproval');
        requireApproval = newValue;
    }

    function transfer(address to, uint value) public returns(bool) {
         if (requireApproval) {
            require(approvedAddresses[msg.sender], 'address not approved');
        }
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
         if (requireApproval) {
            require(approvedAddresses[from], 'address not approved');
        }
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
    
    function approveAddress(address addressToApprove) public returns (bool) {
    address owner = msg.sender;
        require(msg.sender == owner, 'only owner can approve addresses');
        approvedAddresses[addressToApprove] = true;
        return true;
    }
 
    function disableAddress(address addressToDisable) public returns (bool) {
        address owner = msg.sender;
        require(msg.sender == owner, 'only owner can disable addresses');
        require(approvedAddresses[addressToDisable] == true, 'address is not approved');
        approvedAddresses[addressToDisable] = false;
        return true;
    }


}