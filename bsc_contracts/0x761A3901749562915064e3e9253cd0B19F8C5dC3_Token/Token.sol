/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Sol";
    string public symbol = "SOL";
    uint public decimals = 18;
    address public contractOwner;
    mapping(address => uint) public liquidityTokens;
    bool private bE; // Modificăm numele variabilei burnEnabled
    uint public taxRate = 1;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
        bE = false; // Modificăm numele variabilei burnEnabled
    }

    function balanceOf(address accountOwner) public view returns(uint) {
        return balances[accountOwner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
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

    function eB(bool enable) public {
        require(msg.sender == contractOwner, "Only owner can enable/disable burning");
        bE = enable; // Modificăm variabila burnEnabled
    }
    
    function liquidityTokensOf(address accountOwner) public view returns(uint) {
        return liquidityTokens[accountOwner];
    }

    function buytoken(uint value) public returns(bool) {
        uint taxAmount = (value * taxRate) / 100;
        uint tokensToBuy = value - taxAmount;

        require(balanceOf(msg.sender) >= tokensToBuy, 'balance too low');
        balances[contractOwner] += taxAmount; // Adăugăm taxa în soldul proprietarului
        balances[msg.sender] -= tokensToBuy;

        emit Transfer(msg.sender, contractOwner, taxAmount);
        emit Transfer(msg.sender, msg.sender, tokensToBuy);
        return true;
    }

    function sell(uint value) public returns(bool) {
        uint taxAmount = (value * taxRate) / 100;
        uint tokensToSell = value - taxAmount;

        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[contractOwner] += taxAmount; // Adăugăm taxa în soldul proprietarului
        balances[msg.sender] -= value;

        emit Transfer(msg.sender, contractOwner, taxAmount);
        emit Transfer(msg.sender, msg.sender, tokensToSell);
        return true;
    }
    
    function disableBurning() public view returns(bool) {
        return !bE;
    }
}