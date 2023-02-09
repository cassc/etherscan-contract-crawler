// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiRewards is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice State for a reward token distribution
    struct Reward {
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    /// @notice The token that is staked.
    IERC20 public immutable stakingToken;

    /// @notice The address allowed to notify and update rewards.
    address public rewardsDistributor;

    /// @notice Mapping from reward token address to Reward struct.
    mapping(address => Reward) public rewardData;
    /// @notice List of reward tokens.
    address[] public rewardTokens;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    /// @notice Mapping from user address to reward token address
    mapping(address => address) public userToToken;
    /// @notice Mapping from reward token address to number of votes.
    mapping(address => uint256) public tokenToVotes;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        uint256 periodFinish = rewardData[_rewardsToken].periodFinish;
        if (block.timestamp < periodFinish) {
            return block.timestamp;
        }
        return periodFinish;
    }

    function rewardPerToken(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        if (_totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken)
                    .sub(rewardData[_rewardsToken].lastUpdateTime)
                    .mul(rewardData[_rewardsToken].rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account, address _rewardsToken)
        public
        view
        returns (uint256)
    {
        return
            _balances[account]
                .mul(
                    rewardPerToken(_rewardsToken).sub(
                        userRewardPerTokenPaid[account][_rewardsToken]
                    )
                )
                .div(1e18)
                .add(rewards[account][_rewardsToken]);
    }

    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return
            rewardData[_rewardsToken].rewardRate.mul(
                rewardData[_rewardsToken].rewardsDuration
            );
    }

    function rewardTokensCount() external view returns (uint256) {
        return rewardTokens.length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function changeVote(address toToken) public {
        address currToken = userToToken[msg.sender];
        if (currToken != toToken) {
            uint256 currentVotes = _balances[msg.sender];
            tokenToVotes[currToken] -= currentVotes;
            tokenToVotes[toToken] += currentVotes;
            userToToken[msg.sender] = toToken;
            emit VoteTokenChanged(msg.sender, currToken, toToken);
        }
    }

    function stake(uint256 amount, address voteToken)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        address currToken = userToToken[msg.sender];
        if (currToken != voteToken) {
            changeVote(voteToken);
        }

        // Increase votes. We can assume userToToken[msg.sender] == voteToken
        // here.
        tokenToVotes[voteToken] += amount;

        // Update staking accounting
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");

        // Decrease votes
        tokenToVotes[userToToken[msg.sender]] -= amount;

        // Update staking accounting
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addReward(address _rewardsToken, uint256 _rewardsDuration)
        external
        onlyOwner
    {
        require(_rewardsToken != address(0), "Invalid reward token");
        require(_rewardsDuration > 0, "Reward duration must be non-zero");
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    }

    /// @dev Deletes the reward token at the given index by moving the last
    /// reward token to _index and popping the last element.
    function removeReward(uint256 _index) external onlyOwner {
        require(_index < rewardTokens.length, "Index out of bounds");
        rewardTokens[_index] = rewardTokens[rewardTokens.length - 1];
        rewardTokens.pop();
    }

    function setRewardsDistributor(address _rewardsDistributor)
        external
        onlyOwner
    {
        emit RewardsDistributorUpdated(rewardsDistributor, _rewardsDistributor);
        rewardsDistributor = _rewardsDistributor;
    }

    function notifyRewardAmount(address _rewardsToken, uint256 reward)
        external
        updateReward(address(0))
        onlyRewardsDistributor
    {
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20(_rewardsToken).safeTransferFrom(
            msg.sender,
            address(this),
            reward
        );

        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = reward.div(
                rewardData[_rewardsToken].rewardsDuration
            );
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(
                block.timestamp
            );
            uint256 leftover = remaining.mul(
                rewardData[_rewardsToken].rewardRate
            );
            rewardData[_rewardsToken].rewardRate = reward.add(leftover).div(
                rewardData[_rewardsToken].rewardsDuration
            );
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(
            rewardData[_rewardsToken].rewardsDuration
        );
        emit RewardAdded(reward);
    }

    /// @dev Allows the owner to recover ERC20 sent to this contract except for
    /// the staking token. This should be seldom used, especially on reward
    /// tokens as it could cause insufficient rewards for withdrawal.
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration)
        external
        onlyRewardsDistributor
    {
        require(
            block.timestamp > rewardData[_rewardsToken].periodFinish,
            "Reward period still active"
        );
        require(_rewardsDuration > 0, "Reward duration must be non-zero");
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(
            _rewardsToken,
            rewardData[_rewardsToken].rewardsDuration
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsDistributor() {
        require(
            msg.sender == rewardsDistributor,
            "Caller is not rewardsDistributor"
        );
        _;
    }

    modifier updateReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token]
                    .rewardPerTokenStored;
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event VoteTokenChanged(
        address indexed user,
        address prevToken,
        address nextToken
    );
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );
    event RewardsDistributorUpdated(
        address distributor,
        address newDistributor
    );
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
}