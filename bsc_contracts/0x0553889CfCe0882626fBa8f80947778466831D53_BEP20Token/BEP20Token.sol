/**
 *Submitted for verification at BscScan.com on 2023-05-15
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract BEP20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner; // Adresse des Vertragsbesitzers

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);

    // Mapping zur Verfolgung der letzten ausgeführten Transaktion für jeden Benutzer
    mapping(address => uint256) public lastTransactionBlock;

    // Blockzahl, nach der eine neue Transaktion zulässig ist (verhindert Front-Running)
    uint256 public transactionCooldown = 10; // Anzahl der Blöcke als Beispiel, anpassen nach Bedarf

    // Funktion zum Überprüfen der Transaktionscooldown-Zeit
    function checkTransactionCooldown(address _user) internal view returns (bool) {
        return block.number > lastTransactionBlock[_user] + transactionCooldown;
    }

    // Funktion zum Aktualisieren der Transaktionscooldown-Zeit
    function updateTransactionCooldown(address _user) internal {
        lastTransactionBlock[_user] = block.number;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        name = "Pepesbankster";
        symbol = "PEPONE";
        decimals = 10;
        totalSupply = 100000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender; // Setzen Sie den Vertragsbesitzer im Konstruktor
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address"); // Überprüfung der Empfängeradresse
        require(_value > 0, "Invalid amount"); // Überprüfung des Transferbetrags
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
	require(checkTransactionCooldown(msg.sender), "Transaction cooldown period not elapsed");


        uint256 burnAmount = _value / 1000; // 0.1% Burx Tax
        uint256 transferAmount = _value - burnAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        totalSupply -= burnAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Burn(msg.sender, burnAmount);
	
	updateTransactionCooldown(msg.sender);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid address");
       require(_value > 0, "Invalid amount"); // Überprüfung des genehmigten Betrags
      

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
}

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address"); // Überprüfung der Empfängeradresse
        require(_value > 0, "Invalid amount"); // Überprüfung des Transferbetrags
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Not allowed to transfer");

        uint256 burnAmount = _value / 1000; // 0.1% Burn Tax
        uint256 transferAmount = _value - burnAmount;

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.add(balanceOf[_to], transferAmount);
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        totalSupply = SafeMath.sub(totalSupply, burnAmount);

        emit Transfer(_from, _to, transferAmount);
        emit Burn(_from, burnAmount);

        return true;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");

        balanceOf[_to] += _amount;
        totalSupply += _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _amount);
        totalSupply = SafeMath.sub(totalSupply, _amount);

        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
}