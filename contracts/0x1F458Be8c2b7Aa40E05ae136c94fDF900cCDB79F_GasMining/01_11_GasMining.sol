pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Inheritance
import "./interfaces/IGasMining.sol";
import "./Pausable.sol";

// contract GasMining is IGasMining, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
contract GasMining is IGasMining, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public rewardsDistribution;

    IERC20 public rewardsToken;
    uint256 public lastUpdateTime; // probably can remove this too
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userUnlockTime;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public unlockDuration;
    uint256 private _totalSupply;
    uint256 private _totalFundETH;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        uint256 _unlockDuration
    ) public Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        rewardsDistribution = _rewardsDistribution;
        unlockDuration = _unlockDuration;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalFundETH() external view returns (uint256) {
        return _totalFundETH;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function ethBalanceOf(address account) external view returns (uint256) {
        return withdrawableETH(_balances[account]);
    }

    function rewardPerToken() public view returns (uint256) {
        return rewardPerTokenStored;
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function withdrawableETH(uint256 amount) public view returns (uint256) {
        // uint256 amountETH = (amount / _totalSupply) * _totalFundETH;
        return amount.mul(1e27).mul(_totalFundETH).div(_totalSupply).div(1e27);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function() external payable {
        _stake();
    }

    function stake() external payable {
        _stake();
    }

    function _stake() internal nonReentrant notPaused updateReward(msg.sender) {
        uint256 amountETH = msg.value;
        require(amountETH > 0, "Cannot stake 0");

        uint256 amount;
        if (_totalFundETH == 0) {
            amount = amountETH;
        } else {
            // amount = (amountETH / _totalFundETH) * _totalSupply;
            amount = amountETH
                .mul(1e27)
                .mul(_totalSupply)
                .div(_totalFundETH)
                .div(1e27);
        }
        _totalFundETH = _totalFundETH.add(amountETH);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        userUnlockTime[msg.sender] = block.timestamp + unlockDuration;

        emit Staked(msg.sender, amountETH);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");

        uint256 amountETH = withdrawableETH(amount);
        _totalFundETH = _totalFundETH.sub(amountETH);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amountETH);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward()
        public
        nonReentrant
        checkTimeUnlock
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // add more rewards to pool, and transfer eth out
    function notifyRewardAmount(uint256 reward, uint256 amountETH)
        external
        nonReentrant
        onlyOwner
    {
        require(reward > 0, "reward must be greater than 0");
        require(_totalSupply > 0, "there must be stakers");
        // do not spend the vault to zero!
        require(amountETH < _totalFundETH, "not enough eth in contract");

        // add 18 digits of precision
        rewardPerTokenStored = rewardPerTokenStored.add(
            reward.mul(1e18).div(_totalSupply)
        );
        _totalFundETH = _totalFundETH.sub(amountETH);
        msg.sender.transfer(amountETH);
        emit RewardAdded(reward, amountETH);
    }

    function setUnlockDuration(uint256 _duration) external onlyOwner {
        unlockDuration = _duration;
        emit UnlockDurationUpdated(_duration);
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkTimeUnlock {
        require(
            userUnlockTime[msg.sender] < block.timestamp,
            "still in time lock"
        );
        _;
    }

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 spentAmount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event UnlockDurationUpdated(uint256 newDuration);
}