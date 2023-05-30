// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IStakingFactory.sol";

contract Staking is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The precision factor
    uint256 public constant PRECISION_FACTOR = 10**12;
    address public immutable FACTORY;
    IERC20 public immutable YDR_TOKEN;

    // The staked token
    IERC20 public stakedToken;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    uint256 public stakedTokenSupply;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Log(string msg, uint256 var1, uint256 var2, uint256 var3, uint256 var4);

    modifier onlyFactory {
        require(_msgSender() == FACTORY, "Access error");
        _;
    }

    modifier initialized {
        require(address(stakedToken) != address(0), "Not initialized yet");
        _;
    }

    constructor(address ydrToken, address factory) {
        YDR_TOKEN = IERC20(ydrToken);
        FACTORY = factory;
    }

    /**
     * @notice Initialize token
     * @param _stakedToken: staked token address
     */
    function initialize(IERC20 _stakedToken) external onlyFactory {
        require(
            address(stakedToken) == address(0) && address(_stakedToken) != address(0),
            "Already initialize"
        );
        stakedToken = _stakedToken;
        lastRewardBlock = block.number;
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit (in YDR_TOKEN)
     */
    function deposit(uint256 _amount) external nonReentrant initialized {
        require(_amount > 0, "Not allow deposit 0");
        UserInfo storage user = userInfo[_msgSender()];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                YDR_TOKEN.safeTransferFrom(FACTORY, address(_msgSender()), pending);
            }
        }

        uint256 balanceBefore = stakedToken.balanceOf(address(this));
        stakedToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
        uint256 realValue = stakedToken.balanceOf(address(this)) - balanceBefore;
        user.amount = user.amount + realValue;
        stakedTokenSupply += realValue;

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;
        emit Log(
            "Deposit: amountWithoutFee user.amount accTOkenPerShare rewardDebt",
            realValue,
            user.amount,
            accTokenPerShare,
            user.rewardDebt
        );
        emit Deposit(_msgSender(), realValue);
    }

    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in YDR_TOKEN)
     */
    function withdraw(uint256 _amount) external nonReentrant initialized {
        UserInfo storage user = userInfo[_msgSender()];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            stakedToken.safeTransfer(address(_msgSender()), _amount);
        }

        if (pending > 0) {
            YDR_TOKEN.safeTransferFrom(FACTORY, address(_msgSender()), pending);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;

        emit Log(
            "Withdraw: amountWithFee user.amount accTOkenPerShare rewardDebt",
            _amount,
            user.amount,
            accTokenPerShare,
            user.rewardDebt
        );
        emit Withdraw(_msgSender(), _amount);
    }

    /**
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant initialized {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(_msgSender()), amountToTransfer);
            stakedTokenSupply -= amountToTransfer;
        }

        emit EmergencyWithdraw(_msgSender(), amountToTransfer);
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = block.number - lastRewardBlock;
            uint256 rewardPerBlock = _getRewardPerBlock();
            uint256 reward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare =
                accTokenPerShare + (reward * PRECISION_FACTOR) / stakedTokenSupply;
            return (user.amount * adjustedTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return (user.amount * accTokenPerShare) / PRECISION_FACTOR - user.rewardDebt;
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 rewardPerBlock = _getRewardPerBlock();
        uint256 multiplier = block.number - lastRewardBlock;
        uint256 reward = multiplier * rewardPerBlock;
        accTokenPerShare = accTokenPerShare + (reward * PRECISION_FACTOR) / stakedTokenSupply;
        lastRewardBlock = block.number;
        emit Log(
            "Update pool: totalSupply multiplier accTokenPerShare zero",
            stakedTokenSupply,
            multiplier,
            accTokenPerShare,
            0
        );
    }

    function _getRewardPerBlock() internal view returns (uint256) {
        return IStakingFactory(FACTORY).rewardPerBlock(address(stakedToken));
    }
}