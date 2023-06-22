/*
 * RollApp
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IReservoir.sol";

import "../access/Adminable.sol";

/**
 * @title RollAppStaking
 *
 * @dev ERC1155 Staking contract.
 */
contract RollAppStaking is Adminable, Pausable, ERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many ERC1155 tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws ERC1155 tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 tokenId;            // Available tokenId of collection contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. rewardTokens to distribute per block.
        uint256 lastRewardBlock;    // Last block number that rewardTokens distribution occurs.
        uint256 accRewardPerShare;  // Accumulated rewardTokens per share, times 1e18. See below.
    }

    // The REWARD TOKEN!
    IERC20 public rewardToken;
    // Reward tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes ERC1155.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when rewardToken mining starts.
    uint256 public startBlock;

    // Reward token reservoir
    IReservoir public rewardReservoir;

    // ERC1155 collection address
    IERC1155 public collection;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed to, uint256 amount);

    event SetRewardReservoir(address reservoir);
    event SetRewardPerBlock(uint256 rewardPerBlock);

    event WithdrawAlien(IERC20 token, uint256 amount);

    constructor(
        IERC20 _rewardToken,
        IReservoir _rewardReservoir,
        IERC1155 _collection,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _tokenId
    ) public {
        require(address(_rewardToken) != address(0), "RollAppStaking: rewardToken cannot be zero address");
        require(address(_collection) != address(0), "RollAppStaking: collection cannot be zero address");

        rewardToken = _rewardToken;
        rewardReservoir = _rewardReservoir;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        collection = _collection;

        _addPool(1 ether, _tokenId);
    }


    // ** EXTERNAL VIEW functions **

    // View function to see pending rewardTokens on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 tokenSupply = collection.balanceOf(address(this), pool.tokenId);
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardPerShare = accRewardPerShare.add(tokenReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accRewardPerShare).div(1e18).sub(user.rewardDebt);
    }


    // ** ERC1155 Receiver functions **

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, address, uint256[] calldata, uint256[] calldata, bytes calldata
    ) external override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }


    // ** USER public functions **

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply = collection.balanceOf(address(this), pool.tokenId);

        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        tokenReward = rewardReservoir.drip(tokenReward);
        // transfer tokens from rewardReservoir
        pool.accRewardPerShare = pool.accRewardPerShare.add(tokenReward.mul(1e18).div(tokenSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens to RollAppStaking for rewardToken allocation. When not paused.
    function deposit(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                _safeRewardTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            collection.safeTransferFrom(msg.sender, address(this), pool.tokenId, _amount, "0x0");
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw tokens from RollAppStaking.
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            _safeRewardTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            collection.safeTransferFrom(address(this), msg.sender, pool.tokenId, _amount, "0x0");
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e18);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _to) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        collection.safeTransferFrom(address(this), _to, pool.tokenId, amount, "0x0");
        emit EmergencyWithdraw(msg.sender, _to, amount);
    }


    // ** ONLY OWNER OR ADMIN functions **

    // Set reward per block. Can only be called by the owner or admin.
    function setRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwnerOrAdmin {
        if (_withUpdate) {
            updatePool();
        }
        rewardPerBlock = _rewardPerBlock;
        emit SetRewardPerBlock(_rewardPerBlock);
    }


    // ** ONLY OWNER functions **

    // Set rewardReservoir. Can only be called by the owner.
    function setRewardReservoir(IReservoir _rewardReservoir) external onlyOwner {
        rewardReservoir = _rewardReservoir;
        emit SetRewardReservoir(address(_rewardReservoir));
    }

    // Pause deposit function. Can only be called by the owner.
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause deposit function. Can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    // Withdraw alien ERC20 assets. Can only be called by the owner.
    function withdrawAlien(IERC20 _token, uint256 _amount) public onlyOwner {
        require(_token != rewardToken, "withdrawAlien: cannot withdraw reward token");

        uint256 tokenBalance = _token.balanceOf(address(this));
        uint256 withdrawalAmount = (_amount > tokenBalance) ? tokenBalance : _amount;

        _token.safeTransfer(msg.sender, withdrawalAmount);
        emit WithdrawAlien(_token, withdrawalAmount);
    }


    // ** INTERNAL functions **

    // Return reward multiplier over the given _from to _to block.
    function _getMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        return _to.sub(_from);
    }

    // Add a new tokeId to the pool.
    function _addPool(uint256 _allocPoint, uint256 _tokenId) internal {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo = PoolInfo({
            tokenId : _tokenId,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewardPerShare : 0
        });
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewardTokens.
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.safeTransfer(_to, rewardBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}