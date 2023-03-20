/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000000 * 10 ** 18;
    string public name = "Khoreum";
    string public symbol = "KRM";
    uint public decimals = 18;
    address public immutable contractAddress = address(this);
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public owner;
    uint public immutable feePercentage = 10;
    uint public immutable maxOwnerSellPercentage = 10; // max 1% sell or swap in 14 days
    uint public immutable maxOwnerSellPeriod = 14 days;
    uint public ownerSellTime = block.timestamp;
    uint public immutable holderFeePercentage = 9;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event FeeDistributed(uint amount);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        uint fee = (value * feePercentage) / 100;
        uint valueAfterFee = value - fee;
        uint holderFee = (fee * holderFeePercentage) / 100;
        balances[to] += valueAfterFee;
        balances[contractAddress] += fee - holderFee;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, valueAfterFee);
        emit Transfer(msg.sender, contractAddress, fee - holderFee);
        emit FeeDistributed(holderFee);
        distributeFees(holderFee);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        uint fee = (value * feePercentage) / 100;
        uint valueAfterFee = value - fee;
        uint holderFee = (fee * holderFeePercentage) / 100;
        balances[to] += valueAfterFee;
        balances[contractAddress] += fee - holderFee;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, valueAfterFee);
        emit Transfer(from, contractAddress, fee - holderFee);
        emit FeeDistributed(holderFee);
        distributeFees(holderFee);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
   
       function distributeFees(uint amount) internal {
        uint remainingFee = amount;
        uint feeToDistribute = (balanceOf(contractAddress) * remainingFee) / totalSupply;
        if (feeToDistribute > 0) {
            balances[contractAddress] -= feeToDistribute;
            balances[owner] += feeToDistribute;
            emit Transfer(contractAddress, owner, feeToDistribute);
            remainingFee -= feeToDistribute;
        }
        if (remainingFee > 0) {
            feeToDistribute = remainingFee;
            balances[contractAddress] -= feeToDistribute;
            emit Transfer(contractAddress, burnAddress, feeToDistribute);
            remainingFee -= feeToDistribute;
        }
        if (remainingFee > 0) {
            balances[owner] += remainingFee;
            emit FeeDistributed(remainingFee);
        }
    }
}