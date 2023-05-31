// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract MondayNightMadness is Ownable {
    using SafeMath for uint256;

    string public name = "MondayNightMadness";
    string public symbol = "MDM";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private constant _feePercentage = 10; // 10% fee
    address private _feeRecipient;
    uint256 private _liquidityPoolBalance;
    uint256 private _lastLiquidityRewardTime;
    uint256 private _liquidityRewardInterval = 1 weeks;
    address private _liquidityRewardRecipient;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FeeRecipientChanged(address indexed newFeeRecipient);
    event LiquidityRewardSent(address indexed recipient, uint256 amount);
    event LiquidityRewardRecipientChanged(address indexed newRecipient);

    constructor() {
        totalSupply = 100000000000 * (10**18); // 100,000,000,000 tokens with 18 decimal places
        balanceOf[msg.sender] = totalSupply;
        _feeRecipient = msg.sender;
        _liquidityRewardRecipient = msg.sender;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(!isBotAddress(msg.sender), "Bots are not allowed to transfer");
        uint256 feeAmount = (value.mul(_feePercentage)).div(100);
        uint256 transferAmount = value.sub(feeAmount);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        balanceOf[_feeRecipient] = balanceOf[_feeRecipient].add(feeAmount);

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, _feeRecipient, feeAmount);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!isBotAddress(from), "Bots are not allowed to transfer");
        uint256 feeAmount = (value.mul(_feePercentage)).div(100);
        uint256 transferAmount = value.sub(feeAmount);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(transferAmount);
        balanceOf[_feeRecipient] = balanceOf[_feeRecipient].add(feeAmount);

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, _feeRecipient, feeAmount);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient address");
        _feeRecipient = newFeeRecipient;
        emit FeeRecipientChanged(newFeeRecipient);
    }

    function getFeeRecipient() public view returns (address) {
        return _feeRecipient;
    }

    function setLiquidityRewardRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid liquidity reward recipient address");
        _liquidityRewardRecipient = newRecipient;
        emit LiquidityRewardRecipientChanged(newRecipient);
    }

    function getLiquidityRewardRecipient() public view returns (address) {
        return _liquidityRewardRecipient;
    }

    function sendLiquidityReward() external {
        require(block.timestamp >= getNextLiquidityRewardTime(), "Liquidity reward not available yet");
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(_liquidityPoolBalance > 0, "Liquidity pool balance must be greater than 0");

        uint256 rewardAmount = _liquidityPoolBalance.div(totalSupply);
        address recipient = _liquidityRewardRecipient;
        balanceOf[recipient] = balanceOf[recipient].add(rewardAmount);

        _liquidityPoolBalance = _liquidityPoolBalance.sub(rewardAmount);
        _lastLiquidityRewardTime = block.timestamp;

        emit Transfer(address(0), recipient, rewardAmount);
        emit LiquidityRewardSent(recipient, rewardAmount);
    }

    function getNextLiquidityRewardTime() public view returns (uint256) {
        if (_lastLiquidityRewardTime == 0) {
            return 0;
        }
        uint256 nextRewardTime = _lastLiquidityRewardTime.add(_liquidityRewardInterval);
        return nextRewardTime;
    }

    function addLiquidityToPool(uint256 amount) external onlyOwner {
        _liquidityPoolBalance = _liquidityPoolBalance.add(amount);
    }

    function removeLiquidityFromPool(uint256 amount) external onlyOwner {
        require(amount <= _liquidityPoolBalance, "Insufficient liquidity pool balance");
        _liquidityPoolBalance = _liquidityPoolBalance.sub(amount);
    }
}