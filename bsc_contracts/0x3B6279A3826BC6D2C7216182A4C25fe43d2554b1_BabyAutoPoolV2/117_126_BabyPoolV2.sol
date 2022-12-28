// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../core/SafeOwnable.sol';
import '../token/BabyVault.sol';

contract BabyPoolV2 is SafeOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    enum FETCH_VAULT_TYPE {
        FROM_ALL,
        FROM_BALANCE,
        FROM_TOKEN
    }

    IERC20 public immutable token;
    uint256 public startBlock;
    uint256 lastRewardBlock;                    // Last block number that CAKEs distribution occurs.
    uint256 accRewardPerShare;                  // Accumulated CAKEs per share, times 1e12. See below.

    BabyVault public vault;
    uint256 public rewardPerBlock;

    mapping (address => UserInfo) public userInfo;
    FETCH_VAULT_TYPE public fetchVaultType;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    function fetch(address _to, uint _amount) internal returns(uint) {
        if (fetchVaultType == FETCH_VAULT_TYPE.FROM_ALL) {
            return vault.mint(_to, _amount);
        } else if (fetchVaultType == FETCH_VAULT_TYPE.FROM_BALANCE) {
            return vault.mintOnlyFromBalance(_to, _amount);
        } else if (fetchVaultType == FETCH_VAULT_TYPE.FROM_TOKEN) {
            return vault.mintOnlyFromToken(_to, _amount);
        } 
        return 0;
    }
    
    constructor(BabyVault _vault, uint256 _rewardPerBlock, uint256 _startBlock, address _owner) {
        token = _vault.babyToken();
        require(_startBlock >= block.number, "illegal startBlock num");
        startBlock = _startBlock;
        vault = _vault;
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = _startBlock;
        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
        fetchVaultType = FETCH_VAULT_TYPE.FROM_ALL;
    }

    function poolInfo(uint _pid) external view returns (IERC20, uint256, uint256, uint256) {
        require(_pid == 0, "illegal pid");
        return (token, 0, lastRewardBlock, accRewardPerShare);
    }

    function setVault(BabyVault _vault) external onlyOwner {
        require(_vault.babyToken() == token, "illegal vault");
        vault = _vault;
    }

    function setRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        updatePool();
        rewardPerBlock = _rewardPerBlock;
    }

    function setStartBlock(uint _newStartBlock) external onlyOwner {
        require(block.number < startBlock && _newStartBlock >= block.number, "illegal start Block Number");
        startBlock = _newStartBlock;
        lastRewardBlock = _newStartBlock;
    }

    function setFetchVaultType(FETCH_VAULT_TYPE _newType) external onlyOwner {
        fetchVaultType = _newType;
    }

    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 depositSupply = token.balanceOf(address(this));
        if (depositSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint256 reward = multiplier.mul(rewardPerBlock);
        accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(depositSupply));
        lastRewardBlock = block.number;
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint acc = accRewardPerShare;
        uint256 depositSupply = token.balanceOf(address(this));
        if (block.number > lastRewardBlock && depositSupply != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(rewardPerBlock);
            acc = acc.add(reward.mul(1e12).div(depositSupply));
        }
        return user.amount.mul(acc).div(1e12).sub(user.rewardDebt);
    }

    function enterStaking(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                require(fetch(msg.sender, pending) == pending, "out of token");
            }
        }
        if(_amount > 0) {
            token.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    function leaveStaking(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");
        updatePool();
        uint256 pending = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            require(fetch(msg.sender, pending) == pending, "out of token");
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        token.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }
}