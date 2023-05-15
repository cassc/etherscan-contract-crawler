/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "My Token";
    string public symbol = "TKN";
    uint public decimals = 18;
    bool public saleBlocked = true; // Variabilă pentru blocarea vânzării

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
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

    // Funcția pentru blocarea vânzării
    function blockSale() public {
        require(msg.sender == address(this), 'Only contract owner can block sale');
        saleBlocked = true;
    }

    // Funcția pentru deblocarea vânzării
    function unblockSale() public {
        require(msg.sender == address(this), 'Only contract owner can unblock sale');
        saleBlocked = false;
    }

    // Funcția pentru cumpărarea jetoanelor
    function buyTokens() public payable {
        require(!saleBlocked || msg.sender == address(this), 'Token purchase not allowed');
        uint tokenAmount = msg.value;
        balances[msg.sender] += tokenAmount;
        totalSupply += tokenAmount;
        emit Transfer(address(this), msg.sender, tokenAmount);
    }
}