// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WithdrawAll.sol";

contract Finance is WithdrawAll, ReentrancyGuard {

    uint256 public totalReward = 0;

    uint256 public constant ACC_TOKEN_PRECISION = 1e18;
    // Accumulated Tokens per share.
    uint256 public tokenPerShare = 0;
    // Last reward that token update action is executed.
    uint256 public lastReward = 0;
    // The total amount of user shares in each pool. After considering the share boosts.
    uint256 public totalBoostedShare = 0;

    /// @notice Info of each Pledge user.
    /// `amount` token amount the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    /// `pending` Pending Rewards.
    /// `depositTime` Last pledge time
    ///
    /// We do some fancy math here. Basically, any point in time, the amount of Tokens
    /// entitled to a user but is pending to be distributed is:
    ///
    ///   pending reward = (user share * tokenPerShare) - user.rewardDebt
    ///
    ///   Whenever a user deposits or withdraws LP tokens. Here's what happens:
    ///   1. The `tokenPerShare` (and `lastRewardBlock`) gets updated.
    ///   2. User receives the pending reward sent to his/her address.
    ///   3. User's `amount` gets updated. `totalBoostedShare` gets updated.
    ///   4. User's `rewardDebt` gets updated.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pending;
        uint256 total;
        uint256 depositTime;
    }

    /// @notice Info of user.
    mapping(address => UserInfo) public userInfo;

    IERC20 public withdrawToken;
    IERC20 public lpToken;

    event Update(uint256 lastReward, uint256 tokenSupply, uint256 tokenPerShare);
    event UpdateReward(uint256 amout, uint256 time);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawPending(address indexed user, uint256 pending, uint256 time);

    constructor() {
    }

    /// @notice Update reward variables for the given.
    function updateReward(uint256 _amount) external returns (bool){
        require(address(withdrawToken) != address(0), 'Finance: withdrawToken address cannot be empty');

        _amount = _amount == 0 ? withdrawToken.balanceOf(msg.sender) : _amount;

        if (_amount != 0) {
            withdrawToken.transferFrom(msg.sender, address(this), _amount);
            totalReward += _amount;
        }
        emit UpdateReward(_amount, block.timestamp);
        return true;
    }

    /// @notice View function for checking pending Token rewards.
    /// @param _user Address of the user.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _tokenPerShare = tokenPerShare;
        uint256 tokenSupply = totalBoostedShare;

        uint256 multiplier = totalReward - lastReward;
        if (multiplier > 0 && tokenSupply != 0) {

            _tokenPerShare = _tokenPerShare + multiplier * ACC_TOKEN_PRECISION / tokenSupply;
        }

        uint256 boostedAmount = user.amount * _tokenPerShare;
        return boostedAmount / ACC_TOKEN_PRECISION - user.rewardDebt;
    }

    /// @notice Update reward variables for the given.
    function update() public {
        uint256 multiplier = totalReward - lastReward;
        if (multiplier > 0) {
            uint256 tokenSupply = totalBoostedShare;
            if (tokenSupply > 0) {
                tokenPerShare = tokenPerShare + multiplier * ACC_TOKEN_PRECISION / tokenSupply;
            }
            lastReward += multiplier;
            emit Update(multiplier, tokenSupply, tokenPerShare);
        }
    }

    /// @notice Deposit tokens.
    function deposit(uint256 _amount) external nonReentrant {
        update();
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            user.pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        }

        if (_amount > 0) {

            lpToken.transferFrom(msg.sender, address(this), _amount);

            user.amount = user.amount + _amount;

            // Update total boosted share.
            totalBoostedShare = totalBoostedShare + _amount;
        }

        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        user.depositTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraw LP tokens.
    function withdraw(uint256 _amount) external nonReentrant {

        update();

        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= _amount, "Finance: Insufficient");

        user.pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;

        if (_amount > 0) {
            lpToken.transfer(msg.sender, _amount);
            user.amount = user.amount - _amount;
        }
        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        totalBoostedShare = totalBoostedShare - _amount;

        emit Withdraw(msg.sender, _amount);
    }

    /// @notice WithdrawPending LP tokens.
    function withdrawPending() external nonReentrant {

        IERC20 _withdrawToken = withdrawToken;

        require(address(_withdrawToken) != address(0), "Finance: withdrawToken address cannot be empty");

        update();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending = user.pending + (user.amount * tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        user.pending = 0;
        if (pending > 0) {
            _withdrawToken.transfer(msg.sender, pending);
        }

        user.rewardDebt = user.amount * tokenPerShare / ACC_TOKEN_PRECISION;
        user.total += pending;

        emit WithdrawPending(msg.sender, pending, block.timestamp);
    }

    function setWithdrawToken(IERC20 _withdrawToken) external onlyOwner {
        withdrawToken = _withdrawToken;
    }

    function setLpToken(IERC20 _lpToken) external onlyOwner {
        lpToken = _lpToken;
    }
}