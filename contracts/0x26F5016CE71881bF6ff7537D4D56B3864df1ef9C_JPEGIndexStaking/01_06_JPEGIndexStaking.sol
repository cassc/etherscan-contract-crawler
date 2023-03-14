// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract JPEGIndexStaking is ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error ZeroAddress();
    error InvalidAmount();
    error EmptyPool();
    error NoRewards();

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event NewRewards(address indexed from, uint256 amount);

    /// @dev Data relative to a user's staking position
    /// @param amount The amount of LP tokens the user has provided
    /// @param lastAccRewardPerShare The `accRewardPerShare` pool value at the time of the user's last claim
    struct UserInfo {
        uint256 amount;
        uint256 lastAccRewardPerShare;
    }

    /// @dev Data relative to the pool
    /// @param accRewardPerShare Accumulated rewards per share, times 1e36. The amount of rewards the pool has accumulated per unit of LP token deposited
    /// @param depositedAmount Total number of tokens deposited in the pool.
    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 depositedAmount;
    }

    IERC20Upgradeable public jpegIndex;
    PoolInfo public poolInfo;

    mapping(address => UserInfo) public userInfo;

    function initialize(IERC20Upgradeable _jpegIndex) external initializer {
        if (address(_jpegIndex) == address(0)) revert ZeroAddress();

        jpegIndex = _jpegIndex;
    }

    /// @notice Frontend function used to calculate the amount of rewards `_user` can claim from the pool
    /// @param _account The address of the user
    /// @return The amount of rewards claimable by user `_user`
    function pendingReward(address _account) external view returns (uint256) {
        UserInfo storage _user = userInfo[_account];
        uint256 _currentAmount = _user.amount;

        if (_currentAmount == 0) return 0;

        return
            _calculatePendingRewards(
                _currentAmount,
                poolInfo.accRewardPerShare,
                _user.lastAccRewardPerShare
            );
    }

    /// @notice Allows users to deposit `_amount` of JPEG index tokens in the pool. It also claims any pending reward
    /// @dev Emits a {Deposit} event and a {Claim} event if rewards claimed are greater than 0.
    /// @param _amount The amount of LP tokens to deposit
    function deposit(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();

        UserInfo storage _user = userInfo[msg.sender];
        uint256 _currentAmount = _user.amount;

        uint256 _accRewardPerShare = poolInfo.accRewardPerShare;
        uint256 _pending = _calculatePendingRewards(
            _currentAmount,
            _accRewardPerShare,
            _user.lastAccRewardPerShare
        );

        poolInfo.depositedAmount += _amount;
        _user.amount = _currentAmount + _amount;
        _user.lastAccRewardPerShare = _accRewardPerShare;

        jpegIndex.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount);

        if (_pending > 0) {
            _transferETH(msg.sender, _pending);
            emit Claim(msg.sender, _pending);
        }
    }

    /// @notice Allows users to withdraw `_amount` of JPEG Index tokens from the pool. It also claims any pending reward
    /// @dev Emits a {Withdraw} event and a {Claim} event if rewards claimed are greater than 0.
    /// @param _amount The amount of LP tokens to withdraw
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage _user = userInfo[msg.sender];
        uint256 _currentAmount = _user.amount;

        if (_amount == 0 || _amount > _currentAmount) revert InvalidAmount();

        uint256 _accRewardPerShare = poolInfo.accRewardPerShare;
        uint256 _pending = _calculatePendingRewards(
            _currentAmount,
            _accRewardPerShare,
            _user.lastAccRewardPerShare
        );

        unchecked {
            poolInfo.depositedAmount -= _amount;
            _user.amount = _currentAmount - _amount;
        }
        _user.lastAccRewardPerShare = _accRewardPerShare;

        jpegIndex.safeTransfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _amount);

        if (_pending > 0) {
            _transferETH(msg.sender, _pending);
            emit Claim(msg.sender, _pending);
        }
    }

    /// @notice Allows callers to grant ETH rewards.
    /// @dev Emits a {NewRewards} event.
    function notifyReward() external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();

        uint256 _depositedAmount = poolInfo.depositedAmount;
        if (_depositedAmount == 0) revert EmptyPool();

        poolInfo.accRewardPerShare += (msg.value * 1e36) / _depositedAmount;

        emit NewRewards(msg.sender, msg.value);
    }

    /// @notice Allows users to claim rewards from the pool.
    /// @dev Emits a {Claim} event
    function claim() external nonReentrant {
        UserInfo storage _user = userInfo[msg.sender];
        uint256 _currentAmount = _user.amount;

        if (_currentAmount == 0) revert InvalidAmount();

        uint256 _accRewardPerShare = poolInfo.accRewardPerShare;
        uint256 _pending = _calculatePendingRewards(
            _currentAmount,
            _accRewardPerShare,
            _user.lastAccRewardPerShare
        );

        if (_pending == 0) revert NoRewards();

        _user.lastAccRewardPerShare = _accRewardPerShare;
        _transferETH(msg.sender, _pending);

        emit Claim(msg.sender, _pending);
    }

    function _calculatePendingRewards(
        uint256 _depositedAmount,
        uint256 _accRewardPerShare,
        uint256 _lastAccRewardPerShare
    ) internal pure returns (uint256) {
        return
            (_depositedAmount * (_accRewardPerShare - _lastAccRewardPerShare)) /
            1e36;
    }

    function _transferETH(address _recipient, uint256 _amount) internal {
        (bool _success, bytes memory _result) = _recipient.call{
            value: _amount
        }("");
        if (!_success) {
            assembly {
                revert(add(_result, 32), mload(_result))
            }
        }
    }
}