//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract stakingManager is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable; // Wrappers around ERC20 operations that throw on failure

    IERC20Upgradeable public stakeToken; // Token to be staked and rewarded
    address public presaleContract; //presale contract address
    uint256 public tokensStakedByPresale; //total tokens staked by preSale
    uint256 public tokensStaked; // Total tokens staked

    uint256 private lastRewardedBlock; // Last block number the user had their rewards calculated
    uint256 private accumulatedRewardsPerShare; // Accumulated rewards per share times REWARDS_PRECISION
    uint256 public rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations

    uint256 public lockedTime; //To lock the tokens in contract for definite time.
    bool public harvestLock; //To lock the harvest/claim.
    uint public endBlock; //At this block,the rewards generation will be stopped.

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 stakedTime; //the time at tokens staked
        uint256 lastUpdatedBlock; 
        uint256 Harvestedrewards; // The reward tokens quantity the user  harvested
        uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
    }

    //  staker address => PoolStaker
    mapping(address => PoolStaker) public poolStakers;

    mapping(address => uint) public userLockedRewards;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __stakingManager_init(
        address _rewardTokenAddress,
        address _presale,
        uint256 _rewardTokensPerBlock,
        uint _lockTime,
        uint _endBlock
    ) public initializer {
        __Ownable_init_unchained();
        rewardTokensPerBlock = _rewardTokensPerBlock;
        stakeToken = IERC20Upgradeable(_rewardTokenAddress);
        presaleContract = _presale;
        lockedTime = _lockTime;
        endBlock = _endBlock;
    }

    modifier onlyPresale() {
        require(
            msg.sender == presaleContract,
            "This method is only for presale Contract"
        );
        _;
    }

    /**
     * @dev Deposit tokens to the pool
     */
    function deposit(uint256 _amount) external {
        require(block.number < endBlock, "staking has been ended");
        require(_amount > 0, "Deposit amount can't be zero");

        PoolStaker storage staker = poolStakers[msg.sender];

        // Update pool stakers
        harvestRewards();

        // Update current staker
        staker.amount += _amount;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        staker.stakedTime = block.timestamp;
        staker.lastUpdatedBlock = block.number;

        // Update pool
        tokensStaked += _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Deposit tokens to  pool by presale contract
     */
    function depositByPresale(
        address _user,
        uint256 _amount
    ) external onlyPresale {
        require(block.number < endBlock, "staking has been ended");
        require(_amount > 0, "Deposit amount can't be zero");

        PoolStaker storage staker = poolStakers[_user];

        // Update pool stakers
        _harvestRewards(_user);

        // Update current staker
        staker.amount += _amount;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        staker.stakedTime = block.timestamp;

        // Update pool
        tokensStaked += _amount;
        tokensStakedByPresale += _amount;

        // Deposit tokens
        emit Deposit(_user, _amount);
        stakeToken.safeTransferFrom(presaleContract, address(this), _amount);
    }

    /**
     * @dev Withdraw all tokens from existing pool
     */
    function withdraw() external {
        PoolStaker memory staker = poolStakers[msg.sender];
        uint256 amount = staker.amount;
        require(
            staker.stakedTime + lockedTime <= block.timestamp,
            "you are not allowed to withdraw before locked Time"
        );
        require(amount > 0, "Withdraw amount can't be zero");

        // Pay rewards
        harvestRewards();

        //delete staker
        delete poolStakers[msg.sender];

        // Update pool
        tokensStaked -= amount;

        // Withdraw tokens
        emit Withdraw(msg.sender, amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Harvest user rewards
     */
    function harvestRewards() public {
        _harvestRewards(msg.sender);
    }

    /**
     * @dev Harvest user rewards
     */
    function _harvestRewards(address _user) private {
        updatePoolRewards();
        PoolStaker storage staker = poolStakers[_user];
        uint256 rewardsToHarvest = ((staker.amount *
            accumulatedRewardsPerShare) / REWARDS_PRECISION) -
            staker.rewardDebt;
        if (rewardsToHarvest == 0) {
            return;
        }

        staker.Harvestedrewards += rewardsToHarvest;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        if (!harvestLock) {
            if (userLockedRewards[_user] > 0) {
                rewardsToHarvest += userLockedRewards[_user];
                userLockedRewards[_user] = 0;
            }
            emit HarvestRewards(_user, rewardsToHarvest);
            stakeToken.safeTransfer(_user, rewardsToHarvest);
        } else {
            userLockedRewards[_user] += rewardsToHarvest;
        }
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function updatePoolRewards() private {
        if (tokensStaked == 0) {
            lastRewardedBlock = block.number;
            return;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        accumulatedRewardsPerShare =
            accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        lastRewardedBlock = block.number > endBlock ? endBlock : block.number;
    }

    /**
     *@dev To get the number of rewards that user can get
     */
    function getRewards(address _user) public view returns (uint) {
        if (tokensStaked == 0) {
            return 0;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        uint256 accCalc = accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        PoolStaker memory staker = poolStakers[_user];
        return
            ((staker.amount * accCalc) / REWARDS_PRECISION) -
            staker.rewardDebt +
            userLockedRewards[_user];
    }

    function setHarvestLock(bool _harvestlock) external onlyOwner {
        harvestLock = _harvestlock;
    }

    function setPresale(address _presale) external onlyOwner {
        presaleContract = _presale;
    }

    function setStakeToken(address _stakeToken) external onlyOwner {
        stakeToken = IERC20Upgradeable(_stakeToken);
    }

    function setLockedTime(uint _time) external onlyOwner {
        lockedTime = _time;
    }

    function setEndBlock(uint _endBlock) external onlyOwner {
        endBlock = _endBlock;
    }
}