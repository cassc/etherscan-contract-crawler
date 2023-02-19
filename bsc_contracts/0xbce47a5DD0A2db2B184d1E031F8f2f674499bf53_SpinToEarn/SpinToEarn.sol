/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SpinToEarn {
    address public owner;
    address public rewardToken;
    uint256 public rewardTokenAmount;
    uint256 public poolTokenAmount;
    uint256 public taxRate; // in basis points (1 basis point = 0.01%)
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public taxCollected;

    event PoolAdded(address indexed rewardToken, uint256 rewardTokenAmount, uint256 poolTokenAmount);
    event SpinPerformed(address indexed user, uint256 amount, uint256 tax);
    event TaxCollected(address indexed developer, uint256 amount);

    constructor(address _rewardToken, uint256 _rewardTokenAmount, uint256 _poolTokenAmount) {
        owner = msg.sender;
        rewardToken = _rewardToken;
        rewardTokenAmount = _rewardTokenAmount;
        poolTokenAmount = _poolTokenAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function addRewardToken(address _rewardToken, uint256 _rewardTokenAmount) external onlyOwner {
        require(rewardToken == address(0), "Reward token already exists");
        rewardToken = _rewardToken;
        rewardTokenAmount = _rewardTokenAmount;
        emit PoolAdded(_rewardToken, _rewardTokenAmount, poolTokenAmount);
    }

    function setPoolTokenAmount(uint256 _poolTokenAmount) external onlyOwner {
        poolTokenAmount = _poolTokenAmount;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 10000, "Invalid tax rate"); // ensure the tax rate is not more than 100%
        taxRate = _taxRate;
    }

    function spin(uint256 _amount) external {
        require(rewardToken != address(0), "Reward token does not exist");
        IERC20(rewardToken).transferFrom(msg.sender, address(this), rewardTokenAmount);
        uint256 tax = _amount * taxRate / 10000;
        balanceOf[msg.sender] += _amount - tax;
        taxCollected[owner] += tax;
        emit SpinPerformed(msg.sender, _amount, tax);
    }

    function withdraw(uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        balanceOf[msg.sender] -= _amount;
        IERC20(rewardToken).transfer(msg.sender, rewardTokenAmount);
    }

    function collectTax() external onlyOwner {
        require(taxCollected[owner] > 0, "No tax collected");
        IERC20(rewardToken).transfer(owner, rewardTokenAmount);
        emit TaxCollected(owner, taxCollected[owner]);
        taxCollected[owner] = 0;
    }
}