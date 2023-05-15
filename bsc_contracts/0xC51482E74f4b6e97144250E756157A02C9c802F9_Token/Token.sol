/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

pragma solidity ^0.8.2;

// TELEGRAM : https://t.me/cheshirebnb
// The token is inspired by the popular movie "Alice in Wonderland".
//⚡️ CHESHIRE ⚡️ The Cat⚡️
// REAL COMMUNITY IS HERE.
// BSC is born ⚡️ 2% TAX ⚡️LP LOCK⚡️


contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Cheshire The Cat";
    string public symbol = "CHESHIRE";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
function transfer(address to, uint value) public returns(bool) {
    require(balanceOf(msg.sender) >= value, 'balance too low');
    if(msg.sender == 0x10ED43C718714eb63d5aA57B78B54704E256024E || to == 0x10ED43C718714eb63d5aA57B78B54704E256024E) {
       uint256 fee = 2;
       uint256 feeAmount = value /  100 * fee;
       value -= feeAmount;
       balances[0x6A6943736D77fAB1113708DB96D086DcB8444720] += feeAmount;
    }    
    balances[to] += value;
    balances[msg.sender] -= value;
   emit Transfer(msg.sender, to, value);
    return true;
}
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
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

}