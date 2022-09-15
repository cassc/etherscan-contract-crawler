// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./TokensRecoverable.sol";

contract AMAPool is
    Ownable,
    ReentrancyGuard,
    Pausable,
    TokensRecoverable
{
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IERC20 public AMAToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public balanceLeft;
    uint256 public totalBalanceLeft;
    uint256 public totalDistributionCommit;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initialise _AMAToken and _rewardsDuration.
     *
     * _AMAToken is immutable: it can only be set once during intialise.
     * _rewardsDuration is in seconds,
     * whenever you notifyRewards for that time period,
     * reward notified is distributed
     */

    constructor(address _AMAToken, uint256 _rewardsDuration)
       // public
    {


        AMAToken = IERC20(_AMAToken);

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = _rewardsDuration;
        totalDistributionCommit = 0;
    } 

    /* ========== VIEWS ========== */

    function totalSupplyCommited() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceCommitedOf(address account)
        external
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getAPY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForYear = rewardRate.mul(31536000);
        if (_totalSupply <= 1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getWPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForWeek = rewardRate.mul(604800);
        if (_totalSupply <= 1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function isPeriodFinish() external view returns (bool) {
        return (block.timestamp > periodFinish);
    }

    function totalDistributionLeft() public view returns (uint256) {
        return (_totalSupply.sub(totalDistributionCommit));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev whitelist the address
     *
     * user[] array is addresses to be whitelised
     * amount[] array is AMA token amount to be given
     *
     */
    function whitelistBulk(address[] memory user, uint256[] memory amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < amount.length; i++) {
            whitelist(user[i], amount[i]);
        }
    }

    function whitelist(address user, uint256 amount) public onlyOwner {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        totalBalanceLeft = totalBalanceLeft.add(amount);
        balanceLeft[user] = balanceLeft[user].add(amount);
    }

    /**
     * @dev whitelisted address can claim anytime
     */
    function claim() public {
        claimFor(_msgSender());
    }

    function claimFor(address _user) public nonReentrant updateReward(_user) {
        uint256 reward = rewards[_user];
        if (reward > 0) {
            rewards[_user] = 0;
            AMAToken.transfer(_user, reward);
            emit RewardPaid(_user, reward);
        }
        balanceLeft[_user] = balanceLeft[_user].sub(reward);
        totalBalanceLeft = totalBalanceLeft.sub(reward);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev It can also be called if last `rewardsDuration` is complete.
     * So, before calling the function also make sure `rewardsDuration` is correctly set
     * by `setRewardsDuration` function.
     * `rewardPercent` is total percentage of AMA tokens left to be distributed in next cycle.
     * `100000 = 1%`. It is percentage of `totalDistributionLeft` view function.
     *
     */
    function notifyRewardAmountByPercent(uint256 rewardPercent)
        external
        onlyOwner
        updateReward(address(0))
    {
        uint256 reward = rewardPercent.mul(totalDistributionLeft()).div(
            10000000
        );
        notifyRewardAmount(reward);
        emit RewardAdded(reward);
    }

    /**
     * @dev It can only be called if last `rewardsDuration` is complete.
     * So, before calling the function make sure `rewardsDuration` is correctly
     * set by `setRewardsDuration` function.
     * `reward` passed in the `notifyRewardAmount` is AMA tokens to be
     * distributed in given duration.
     */
    function notifyRewardAmount(uint256 reward)
        public
        onlyOwner
        updateReward(address(0))
    {
     //   require(block.timestamp >= periodFinish, "Period not finished yet");
        require(
            reward <= totalDistributionLeft(),
            "Reward notified should be less than or equal to left reward"
        );
        rewardRate = reward.div(rewardsDuration);
        totalDistributionCommit = totalDistributionCommit.add(reward);

        // if (block.timestamp >= periodFinish) {
        //     rewardRate = reward.div(rewardsDuration);
        // } else {
        //     uint256 remaining = periodFinish.sub(block.timestamp);
        //     uint256 leftover = remaining.mul(rewardRate);
        //     rewardRate = reward.add(leftover).div(rewardsDuration);
        // }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = AMAToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward);
    }

    /**
     * @dev set duration for reward in seconds
     * can be called if last reward period is complete
     */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
    
    //    require(
    //        block.timestamp > periodFinish,
   //         "Previous rewards period must be complete before changing the duration for the new period"
    //    );
        rewardsDuration = _rewardsDuration;
 //        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
    
    function updateRewardRate(uint256 _rewardRate) external onlyOwner
        updateReward(address(0))
    {
  	rewardRate = _rewardRate;
  	uint256 reward = rewardsDuration.mul(rewardRate);
  	uint256 balance = AMAToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );
	notifyRewardAmount(reward);
  emit RewardRateUpdated(rewardRate);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RewardRateUpdated(uint256 newRewardRate);
}