// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/INichoToken.sol";

/// @title  Nicho Farm
/// @author Cui-Kyo
/// @notice Yield farming dApp to reward locking Nicho token
/// @dev With new staking positions and withdraw the rewards are computed.

///
/// pending reward = (user.amount  * accTokenPerShare) - user.rewardDebt  <<<< Wallet Earn (WE)
///
/// Whenever an user deposits or withdraws LP tokens to the pool:
///   1. The pool's `accTokenPerShare` (and `lastRewardTime`) gets updated
///   2. User receives the pending reward sent to their address
///   3. User's `amount` gets updated
///   4. User's `rewardDebt` gets updated

contract NichoFarm is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// Info on each user
    struct UserInfo {
        /// User Address
        address userAddr;
        /// tokens locked in NichoFarm by the user
        uint256 amount;
        /// update accTokensPerShare to new rate whenever user do any action
        uint256 lastRate;
        /// Pending Reward Amount for Frontend Side
        uint256 earnedAmount;
        /// Info that user deposited already for userList array
        bool isDeposited;
    }

    address[] public userList;
    /// Nicho Token
    IERC20 public nichoToken;

    /// Last block when reward distribution has been completed for this pool
    uint256 public lastRewardBlock;
    /// Reward tokens per share including decimals
    uint256 public accTokenPerShare;
    /// Tokens deposited in the pool, starts at 0
    uint256 public totalDepositAmount;
    /// Reward tokens per block: Farming Rate (FR) logic
    uint256 public tokensPerBlock;

    /// Nicho Token's decimal (10^9)
    uint256 public constant tokenDecimals = 10 ** 9;
    /// The precision factor
    uint256 public constant PRECISION_FACTOR = 10 ** 9;

    /// Info of each user that enters the farm
    mapping(address => UserInfo) public userInfo;

    /// Event for Claim the reward
    event YieldWithdraw(address user, uint256 pendingReward);
    /// Event for EmergencyWithdraw
    event EmergencyWithdraw(address user, uint256 claimAmount);
    /// Event for Deposit Nicho Tokens to staking pool
    event Deposit(address user, uint256 depositAmount);
    /// Event for Withdraw Nicho Tokens from staking pool
    event Withdraw(address user, uint256 withdrawAmount);

    constructor(IERC20 _nichoToken, uint256 _tokensPerBlock) {
        require(_nichoToken.totalSupply() > 0, "Invalid token");
        require(_tokensPerBlock >= 0, "Invalid amount");

        nichoToken = _nichoToken;
        tokensPerBlock = _tokensPerBlock;
        /// This variable should be initialized by factor
        accTokenPerShare = PRECISION_FACTOR;
    }

    /// Admin function (update tokensPerBlock)
    function updateTokensPerBlock(uint256 _tokensPerBlock) external onlyOwner {
        require(_tokensPerBlock != tokensPerBlock, "Already in use");
        require(totalDepositAmount == 0, "Deposit already started");
        tokensPerBlock = _tokensPerBlock;
    }

    /// Admin function (deposit nicho token for reward)
    function depositRewardToken(uint256 amount) external onlyOwner {
        nichoToken.safeTransferFrom(owner(), address(this), amount);
    }

    /// Number of Nicho Tokens provided by user on a staking pool
    function getStakedAmount(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        return user.amount;
    }

    /// Get Total Deposit Amount for frontend side
    function getTotalDepositAmount() external view returns (uint256) {
        if (block.number <= lastRewardBlock) {
            return totalDepositAmount;
        }
        if (totalDepositAmount == 0) {
            return totalDepositAmount;
        }
        uint256 multiplier = block.number - lastRewardBlock;
        uint256 tokensReward = multiplier * tokensPerBlock;

        return totalDepositAmount + tokensReward;
    }

    /// View functoin to see pending Tokens (For Frontend Side)
    function pendingTokens(
        address _user
    ) public view returns (uint256 pending) {
        UserInfo memory user = userInfo[_user];
        if (user.amount == 0 || user.lastRate == 0) {
            return 0;
        }
        uint256 accTokensPerShare = accTokenPerShare;
        uint256 depositAmount = totalDepositAmount;

        if (block.number > lastRewardBlock && depositAmount != 0) {
            uint256 multiplier = block.number - lastRewardBlock;
            uint256 tokensReward = multiplier * tokensPerBlock;
            /// uint256 newAccTokenPerShare = accTokenPerShare * (PRECISION_FACTOR + PRECISION_FACTOR * newReward / totalDepositAmount) / PRECISION_FACTOR =
            /// = accTokenPerShare + accTokenPerShare * newReward / totalDepositAmount
            accTokensPerShare += ((accTokensPerShare * tokensReward) /
                depositAmount);
        }

        pending =
            (user.amount * (accTokensPerShare - user.lastRate)) /
            user.lastRate;
    }

    // Get User List's Info for Frontend
    function getUserListInfo() external view returns (UserInfo[] memory) {
        UserInfo[] memory userInfoList = new UserInfo[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            uint256 pendingAmount = pendingTokens(userList[i]);
            userInfoList[i] = userInfo[userList[i]];
            userInfoList[i].amount += pendingAmount;
            userInfoList[i].earnedAmount += pendingAmount;
        }

        return userInfoList;
    }

    // Get User List's Info for Frontend
    function getUserInfo(
        address _sender
    ) external view returns (UserInfo memory) {
        UserInfo memory _userInfo = userInfo[_sender];
        uint256 pendingAmount = pendingTokens(_sender);
        _userInfo.amount += pendingAmount;
        _userInfo.earnedAmount += pendingAmount;

        return _userInfo;
    }

    /// Update reward variables of the given pool to be up-to-date.
    function updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalDepositAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - lastRewardBlock;
        uint256 tokensReward = multiplier * tokensPerBlock;
        /// uint256 newAccTokenPerShare = accTokenPerShare * (PRECISION_FACTOR + PRECISION_FACTOR * newReward / totalDepositAmount) / PRECISION_FACTOR =
        /// = accTokenPerShare + accTokenPerShare * newReward / totalDepositAmount
        accTokenPerShare +=
            (accTokenPerShare * tokensReward) /
            totalDepositAmount;
        /// Update last rewarded block
        lastRewardBlock = block.number;
        /// Update this value because reward need to be compounded
        totalDepositAmount = totalDepositAmount + tokensReward;
    }

    /// Deposit Nicho Token
    function deposit(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Wrong amount");

        updatePool();

        nichoToken.safeTransferFrom(_msgSender(), address(this), _amount);

        UserInfo storage user = userInfo[_msgSender()];
        if (user.lastRate == 0) {
            user.lastRate = accTokenPerShare;
        }
        uint256 newAmountIncludingLastRewards = (user.amount *
            accTokenPerShare) / (user.lastRate);

        user.earnedAmount += (newAmountIncludingLastRewards - user.amount);
        /// update share rate to new
        user.lastRate = accTokenPerShare;
        /// add deposit amount for user
        user.amount = newAmountIncludingLastRewards + _amount;
        /// add deposit amount for total
        totalDepositAmount += _amount;
        if (!user.isDeposited) {
            user.isDeposited = true;
            user.userAddr = msg.sender;
            userList.push(msg.sender);
        }

        emit Deposit(_msgSender(), _amount);
    }

    /// Withdraw staked Nicho tokens
    function withdraw(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Wrong Amount");

        updatePool();

        UserInfo storage user = userInfo[_msgSender()];
        uint256 newAmountIncludingLastRewards = (user.amount *
            accTokenPerShare) / user.lastRate;
        user.lastRate = accTokenPerShare;
        user.earnedAmount += (newAmountIncludingLastRewards - user.amount);

        require(
            newAmountIncludingLastRewards >= _amount,
            "Insufficient withdrawable balance"
        );

        uint256 withdrawAmount = _amount;
        user.amount = newAmountIncludingLastRewards - _amount;
        if (user.amount <= tokensPerBlock) {
            user.amount = 0;
            withdrawAmount = newAmountIncludingLastRewards;
        }

        require(
            totalDepositAmount >= withdrawAmount,
            "Insufficient withdrawable balance"
        );
        if (user.amount == 0) {
            /// free up storage space and get gas refund
            delete userInfo[_msgSender()];
            removeUserFromUserList(_msgSender());
        }
        totalDepositAmount -= withdrawAmount;

        nichoToken.safeTransfer(address(_msgSender()), withdrawAmount);

        emit Withdraw(_msgSender(), withdrawAmount);
    }

    /// Remove user from user List
    function removeUserFromUserList(address _sender) private {
        uint256 userLength = userList.length;
        for (uint256 i = 0; i < userLength; i++) {
            if (userList[i] == _sender) {
                if (i < userLength - 1) {
                    userList[i] = userList[userLength - 1];
                }
            }
        }
        userList.pop();
    }

    /// Withdraw and waive any accrued rewards. EMERGENCY ONLY,  as users lose their rewards by calling this.
    function emergencyWithdraw() public whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        uint256 claimAmount = user.amount;
        user.amount = 0;
        require(
            claimAmount > 0 && totalDepositAmount >= claimAmount,
            "Not enough tokens in this pool to withdraw"
        );

        totalDepositAmount -= claimAmount;
        nichoToken.safeTransfer(address(_msgSender()), claimAmount);

        emit EmergencyWithdraw(_msgSender(), claimAmount);

        //free up storage space and get gas refund
        delete userInfo[_msgSender()];
        removeUserFromUserList(_msgSender());
    }

    function withdrawRewardToken() public whenPaused nonReentrant onlyOwner {
        nichoToken.safeTransfer(
            _msgSender(),
            nichoToken.balanceOf(address(this)) - totalDepositAmount
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* Just in case anyone sends tokens by accident to this contract */

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "NichoFarm");
    }

    function withdrawETH() external payable onlyOwner {
        safeTransferETH(_msgSender(), address(this).balance);
    }

    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        require(
            address(nichoToken) != address(_tokenContract),
            "Owner couldn't withdraw user's staked Nicho Token!"
        );

        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }
}