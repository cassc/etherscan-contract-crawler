// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFactory.sol";

contract Farm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice information stuct on each user than stakes LP tokens.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 unlockPeriod;
        uint256 depositTime;
    }

    /// @notice all the settings for this farm in one struct
    struct FarmInfo {
        IERC20 lpToken;
        IERC20 rewardToken;
        uint256 startBlock;
        uint256 blockReward;
        uint256 bonusEndBlock;
        uint256 bonus;
        uint256 endBlock;
        uint256 lastRewardBlock; // Last block number that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e12
        uint256 farmableSupply; // set in init, total amount of tokens farmable
        uint256 numFarmers;
        uint256 lockPeriod;
    }

    IFactory public factory;
    address public farmGenerator;

    FarmInfo public farmInfo;

    /// @notice information on each user than stakes LP tokens
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(address _factory, address _farmGenerator) {
        factory = IFactory(_factory);
        farmGenerator = _farmGenerator;
    }

    /**
     * @notice initialize the farming contract. This is called only once upon farm creation and the FarmGenerator ensures the farm has the correct paramaters
     */
    function init(
        FarmInfo memory _farmInfo
    ) public {
        require(msg.sender == address(farmGenerator), "FORBIDDEN");

        // _rewardToken.safeTransferFrom(
        //     msg.sender,
        //     address(this),
        //     _amount
        // );
        farmInfo.rewardToken = _farmInfo.rewardToken;

        farmInfo.startBlock = _farmInfo.startBlock;
        farmInfo.blockReward = _farmInfo.blockReward;
        farmInfo.bonusEndBlock = _farmInfo.bonusEndBlock;
        farmInfo.bonus = _farmInfo.bonus;

        uint256 lastRewardBlock = block.number > _farmInfo.startBlock
            ? block.number
            : _farmInfo.startBlock;
        farmInfo.lpToken = _farmInfo.lpToken;
        farmInfo.lastRewardBlock = lastRewardBlock;
        farmInfo.accRewardPerShare = 0;

        farmInfo.endBlock = _farmInfo.endBlock;
        farmInfo.farmableSupply = _farmInfo.farmableSupply;
        farmInfo.lockPeriod = _farmInfo.lockPeriod;
    }

    /**
     * @notice Gets the reward multiplier over the given _from_block until _to block
     * @param _from_block the start of the period to measure rewards for
     * @param _to the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _from_block, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 _from = _from_block >= farmInfo.startBlock
            ? _from_block
            : farmInfo.startBlock;
        uint256 to = farmInfo.endBlock > _to ? _to : farmInfo.endBlock;
        if (to <= farmInfo.bonusEndBlock) {
            return to.sub(_from).mul(farmInfo.bonus);
        } else if (_from >= farmInfo.bonusEndBlock) {
            return to.sub(_from);
        } else {
            return
                farmInfo.bonusEndBlock.sub(_from).mul(farmInfo.bonus).add(
                    to.sub(farmInfo.bonusEndBlock)
                );
        }
    }

    /**
     * @notice function to see accumulated balance of reward token for specified user
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = farmInfo.accRewardPerShare;
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (block.number > farmInfo.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                farmInfo.lastRewardBlock,
                block.number
            );
            uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
            accRewardPerShare = accRewardPerShare.add(
                tokenReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 reward = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if(user.unlockPeriod > 0) {
            reward = reward.mul(user.unlockPeriod.div(farmInfo.lockPeriod));
        }
        return reward;
            
    }

    /**
     * @notice updates pool information to be up to date to the current block
     */
    function updatePool() public {
        if (block.number <= farmInfo.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = farmInfo.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            farmInfo.lastRewardBlock = block.number < farmInfo.endBlock
                ? block.number
                : farmInfo.endBlock;
            return;
        }
        uint256 multiplier = getMultiplier(
            farmInfo.lastRewardBlock,
            block.number
        );
        uint256 tokenReward = multiplier.mul(farmInfo.blockReward);
        farmInfo.accRewardPerShare = farmInfo.accRewardPerShare.add(
            tokenReward.mul(1e12).div(lpSupply)
        );
        farmInfo.lastRewardBlock = block.number < farmInfo.endBlock
            ? block.number
            : farmInfo.endBlock;
    }

    /**
     * @notice deposit LP token function for msg.sender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(farmInfo.accRewardPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeRewardTransfer(msg.sender, pending);
        }
        if (user.amount == 0 && _amount > 0) {
            factory.userEnteredFarm(msg.sender);
            farmInfo.numFarmers++;
        }
        farmInfo.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12);
        user.unlockPeriod = 0;
        user.depositTime = block.timestamp;
        emit Deposit(msg.sender, _amount);
    }

    function lock(uint256 _period) public {
        UserInfo storage user = userInfo[msg.sender];
        user.unlockPeriod = _period;
    }

    /**
     * @notice withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "INSUFFICIENT");
        require(user.unlockPeriod + user.depositTime <= block.timestamp, "You can't withdraw now.");
        updatePool();
        if (user.amount == _amount && _amount > 0) {
            factory.userLeftFarm(msg.sender);
            farmInfo.numFarmers--;
        }
        uint256 pending = user
            .amount
            .mul(farmInfo.accRewardPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        // calculate booster
        if(user.unlockPeriod > 0) {
            pending = pending.mul(user.unlockPeriod.div(farmInfo.lockPeriod));
        }
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(farmInfo.accRewardPerShare).div(1e12);
        farmInfo.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice emergency functoin to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        farmInfo.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        if (user.amount > 0) {
            factory.userLeftFarm(msg.sender);
            farmInfo.numFarmers--;
        }
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = farmInfo.rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            farmInfo.rewardToken.transfer(_to, rewardBal);
        } else {
            farmInfo.rewardToken.transfer(_to, _amount);
        }
    }
}