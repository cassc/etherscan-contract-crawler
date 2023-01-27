// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleStaking is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    
    mapping(address => uint256) public userAmounts;
    mapping(address => uint256) public userClaimed;
    EnumerableSet.AddressSet private addresses;
    uint256 public stakersCount;
    uint256 public totalStakedTokens;
    IERC20 public stakingToken;
    uint256 public totalRewards;
    uint256 public claimedRewards;
    bool public locked = false;
    bool public claimable = false;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    
    constructor(){
        stakingToken = IERC20(0x4a72AF9609d22Bf2fF227AEC333c7d0860f3dB36);
    }
    
    receive() external payable {
        totalRewards += msg.value;
    }
    
    function setStatus(bool locked_, bool claimable_) external onlyOwner {
        locked = locked_;
        claimable = claimable_;
    }
    
    function getAddresses() external view returns(address[] memory) {
        address[] memory result = new address[](addresses.length());
        for (uint256 i = 0; i < addresses.length(); i++) {
            result[i] = addresses.at(i);
        }
        return result;
    }
    
    function deposit(uint256 amount) external virtual  {
        require(!claimable, "Deposit is not allowed during claim period");
        address account = msg.sender;
        
        addresses.add(account);
        
        if (amount > 0) {
            stakingToken.safeTransferFrom(address(account), address(this), amount);
            stakersCount += userAmounts[account] == 0 ? 1 : 0;
            userAmounts[account] += amount;
            totalStakedTokens += amount;
        }
        
        emit Deposit(account, amount);
    }
    
    function withdraw(uint256 amount) external virtual  {
        address account = msg.sender;
        require(!locked, "Staking is locked");
        
        addresses.remove(account);
        require(userAmounts[account] >= amount, 'Withdrawing more than you have!');
        
        if (amount > 0) {
            userAmounts[account] -= amount;
            stakersCount -= userAmounts[account] == 0 && stakersCount > 0 ? 1 : 0;
            stakingToken.safeTransfer(account, amount);
            totalStakedTokens -= amount;
        }
        
        emit Withdraw(account, amount);
    }
    
    function claim() external virtual  {
        require(claimable, "Claiming is not allowed");
        address account = msg.sender;
        uint256 totalAmount = userAmounts[account] * totalRewards / totalStakedTokens;
        require(totalAmount > userClaimed[account], 'Nothing to claim!');
        uint256 amount = totalAmount - userClaimed[account];
        require(amount > 0, 'Nothing to claim!');
        
        userClaimed[account] += amount;
        claimedRewards += amount;
        payable(account).transfer(amount);
        
        emit Claim(account, amount);
    }
    
    function withdrawRewards() external virtual onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        totalRewards = 0;
    }
}