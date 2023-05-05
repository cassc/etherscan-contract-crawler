/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PEPEBABY {
    string public name = "PEPEBABY";
    string public symbol = "PPB";
    uint256 public totalSupply = 200_000000000000 * (10 ** 18) ; // 200 billones en supply
    uint8 public decimals = 18;
   
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
   
    uint256 public buyFee = 4;
    uint256 public sellFee = 4;
    bool public isPaused = false;
   
    address public owner;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Pause(bool isPaused);
    event BuyFeeChanged(uint256 newFee);
    event SellFeeChanged(uint256 newFee);
    event Burn(address indexed burner, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
   
    function transfer(address to, uint256 value) public returns (bool success) {
        require(!isPaused, "Token transfers are paused");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
       
        uint256 fee = msg.sender == owner ? 0 : (msg.sender == address(this) ? sellFee : buyFee);
        uint256 taxedValue = value - (value * fee / 100);
       
        balanceOf[msg.sender] -= value;
        balanceOf[to] += taxedValue;
       
        emit Transfer(msg.sender, to, taxedValue);
        return true;
    }
   
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
   
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(!isPaused, "Token transfers are paused");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
       
        uint256 fee = from == owner ? 0 : (msg.sender == address(this) ? sellFee : buyFee);
        uint256 taxedValue = value - (value * fee / 100);
       
        balanceOf[from] -= value;
        balanceOf[to] += taxedValue;
        allowance[from][msg.sender] -= value;
       
        emit Transfer(from, to, taxedValue);
        return true;
    }
   
    function pause(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
        emit Pause(isPaused);
    }
   
    function setBuyFee(uint256 _buyFee) public onlyOwner {
        require(_buyFee <= 10, "Buy fee must be less than or equal to 10%");
        buyFee = _buyFee;
        emit BuyFeeChanged(buyFee);
    }
   
    function setSellFee(uint256 _sellFee) public onlyOwner {
        require(_sellFee <= 10, "Sell fee must be less than or equal to 10%");
        sellFee = _sellFee;
        emit SellFeeChanged(sellFee);
    }

    function burn(uint256 amount) public onlyOwner {
    require(balanceOf[msg.sender] >= amount, "Insufficient balance");
    require(totalSupply - amount >= 0, "Burn amount exceeds total supply");

    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;

    emit Transfer(msg.sender, address(0), amount);
}


}