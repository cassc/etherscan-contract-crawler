pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Inheritance
import "./interfaces/IStakingRewards.sol";
import "./interfaces/ILottery.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant ITEMS_CONTRACT = keccak256("ITEMS_CONTRACT");

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;
    ILottery public lotteryContract;
    uint256 public periodFinish = 0;
    uint256 public rewardCandyCount = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 1825 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IStakingRewards public oldStakingRewards;
    bool isMigrationComplete;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _stakingToken,
        address _lotteryContract,
        address _owner
    ) public {
        stakingToken = IERC20(_stakingToken);
        lotteryContract = ILottery(_lotteryContract);
        rewardsDistribution = _rewardsDistribution;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(ADMIN, _owner);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public override view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public override view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public override view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external override view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function enterLottery(uint256 candyAmount) public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0 && reward >= candyAmount) {
            require(candyAmount >= 1 ether, "You don't have enough candies to enter the lottery");
            uint256 candiesInETH = candyAmount.div(1e18);
            
            lotteryContract.enter(candiesInETH, msg.sender);
            uint256 candiesInWei = candiesInETH.mul(1e18);

            rewards[msg.sender] = reward - candiesInWei;
            rewardCandyCount -= candiesInWei;
            emit EnteredLottery(msg.sender, candiesInETH);
        }
        else {
            require(1 == 0, 'Not working');
        }
    }

    function buyItemWithCandies(address user, uint256 candyAmount) override public nonReentrant updateReward(user) {
        require(hasRole(ITEMS_CONTRACT, _msgSender()), 'StakingRewards::buyItemsWithCandies: Unauthorized');
        uint256 reward = rewards[user];
        if (reward > 0 && reward >= candyAmount) {
            rewards[user] = reward - candyAmount;
            rewardCandyCount -= candyAmount;
            emit ItemsPurchased(user, candyAmount);
        }
        else {
            require(1 == 0, 'StakingRewards::buyItemsWithCandies: Not enough rewards');
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        enterLottery(rewards[msg.sender]);
    }

    // set old staking rewards
    function setLotteryAddress(address _lotteryAddress) external {
        require(hasRole(ADMIN, _msgSender()), 'StakingRewards::setLotteryAddress: Unauthorized');

        lotteryContract = ILottery(_lotteryAddress);
    }

    function setOldStakingContract(address _stakingContract) 
    external 
    virtual {
        require(hasRole(ADMIN, _msgSender()), 'StakingRewards::setOldStakingContract: Unauthorized');
        oldStakingRewards = IStakingRewards(_stakingContract);
    }
    
    // migrate tickets from old staking rewards
    function migrateTickets() external nonReentrant {
        address sender = msg.sender;
        uint256 balanceToMigrate = oldStakingRewards.earned(sender);

        require(balanceToMigrate > 0, 'StakingRewards::migrateTickets: Not tickets to migrate');

        oldStakingRewards.buyItemWithCandies(sender, balanceToMigrate);
        rewards[sender] = rewards[sender].add(balanceToMigrate);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyCandyAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        rewardCandyCount = reward;
        require(rewardRate <= rewardCandyCount.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
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
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EnteredLottery(address indexed user, uint256 candies);
    event ItemsPurchased(address indexed user, uint256 candies);
}

interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}