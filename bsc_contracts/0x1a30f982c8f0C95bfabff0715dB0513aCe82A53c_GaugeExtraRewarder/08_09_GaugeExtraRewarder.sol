// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/SignedSafeMath.sol";


interface IRewarder {
    function onReward(uint256 pid, address user, address recipient, uint256 lqdrAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 lqdrAmount) external view returns (IERC20[] memory, uint256[] memory);
}

interface IGauge {
    function TOKEN() external view returns(address);
}


contract GaugeExtraRewarder is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    bool public stop = false;

    IERC20 public immutable rewardToken;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Struct of pool info
   
    struct PoolInfo {
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
    }

    /// @notice pool info
    PoolInfo public poolInfo;

    /// @notice Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;

    uint public lastDistributedTime;
    uint public rewardPerSecond;
    uint public distributePeriod = 86400 * 7;
    uint public ACC_TOKEN_PRECISION = 1e12;


    address private immutable GAUGE;

    event LogOnReward(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);

    constructor (IERC20 _rewardToken, address gauge) {
        rewardToken = _rewardToken;
        poolInfo = PoolInfo({
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0
        });
        GAUGE = gauge;
    }


    function onReward(uint256 /*pid*/, address _user, address to, uint256 /*extraData*/, uint256 lpToken) onlyGauge external {
        if(stop){
            return;
        }
        
        PoolInfo memory pool = updatePool();
        UserInfo storage user = userInfo[_user];
        uint256 pending;
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (user.amount > 0) {
            pending = int256( user.amount.mul(accRewardPerShare) / ACC_TOKEN_PRECISION ).sub(user.rewardDebt).toUInt256();
            rewardToken.safeTransfer(to, pending);
        }
        user.amount = lpToken;
        user.rewardDebt = int256(lpToken.mul(pool.accRewardPerShare) / ACC_TOKEN_PRECISION);
    }


    /// @notice View function to see pending WBNB on frontend.
    /// @param _user Address of user.
    /// @return pending rewardToken reward for a given user.
    function pendingReward(address _user) external view returns (uint256 pending){
        PoolInfo memory pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = IERC20(IGauge(GAUGE).TOKEN()).balanceOf(GAUGE);

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTime);
            uint256 reward = time.mul(rewardPerSecond);
            accRewardPerShare = accRewardPerShare.add( reward.mul(ACC_TOKEN_PRECISION) / lpSupply );
        }
        pending = int256( user.amount.mul(accRewardPerShare) / ACC_TOKEN_PRECISION ).sub(user.rewardDebt).toUInt256();
    }


    modifier onlyGauge {
        require(msg.sender == GAUGE,"!GAUGE");
        _;
    }



    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of Reward to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
    }


    function setDistributionRate(uint256 amount) public onlyOwner {
        updatePool();
        require(IERC20(rewardToken).balanceOf(address(this)) >= amount);
        uint256 notDistributed;
        if (lastDistributedTime > 0 && block.timestamp < lastDistributedTime) {
            uint256 timeLeft = lastDistributedTime.sub(block.timestamp);
            notDistributed = rewardPerSecond.mul(timeLeft);
        }

        amount = amount.add(notDistributed);
        uint256 _rewardPerSecond = amount.div(distributePeriod);
        rewardPerSecond = _rewardPerSecond;
        lastDistributedTime = block.timestamp.add(distributePeriod);
    }



    /// @notice Update reward variables of the given pool.
    /// @return pool Returns the pool that was updated.
    function updatePool() public returns (PoolInfo memory pool) {
        pool = poolInfo;

        if (block.timestamp > pool.lastRewardTime) {
            uint256 lpSupply = IERC20(IGauge(GAUGE).TOKEN()).balanceOf(GAUGE);
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = time.mul(rewardPerSecond);
                pool.accRewardPerShare = pool.accRewardPerShare.add( reward.mul(ACC_TOKEN_PRECISION).div(lpSupply) );
            }
            pool.lastRewardTime = block.timestamp;
            poolInfo = pool;
        }
    }


    function recoverERC20(uint amount, address token) external onlyOwner {
        require(amount > 0);
        require(token != address(0));
        require(IERC20(token).balanceOf(address(this)) >= amount);
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function stopRewarder() external onlyOwner {
        stop = true;
    }

    function startRewarder() external onlyOwner {
        stop = false;
    }


}