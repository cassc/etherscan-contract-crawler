/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

pragma solidity ^0.8.0;

contract CustomERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    address public owner;
    uint256 public buyFee;
    uint256 public sellFee;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        owner = msg.sender;
        totalSupply = 1000000000 * 10**decimals; // 1 миллиард токенов
        emit Transfer(address(0), owner, totalSupply);
        buyFee = 300;
        sellFee = 500;
    }

    function setBuyFee(uint256 newBuyFee) external onlyOwner {
        require(newBuyFee >= 0 && newBuyFee <= 10000, "Invalid buy fee");
        buyFee = newBuyFee;
    }

    function setSellFee(uint256 newSellFee) external onlyOwner {
        require(newSellFee >= 0 && newSellFee <= 10000, "Invalid sell fee");
        sellFee = newSellFee;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(to != address(0), "Cannot transfer to the zero address");

        uint256 fee;
        if (from == owner) {
            fee = (value * buyFee) / 10000;
        } else if (to == owner) {
            fee = (value * sellFee) / 10000;
        } else {
            fee = 0;
        }

        uint256 amountAfterFee = value - fee;
        balanceOf[from] -= value;
        balanceOf[to] += amountAfterFee;

        if (fee > 0) {
            balanceOf[owner] += fee;
        }

                emit Transfer(from, to, amountAfterFee);

        if (fee > 0) {
            emit Transfer(from, owner, fee);
        }
    }
}