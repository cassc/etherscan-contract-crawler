// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./RolesManager.sol";
import "../interfaces/IMultipleRewardPool.sol";

abstract contract MultipleRewardPool is IMultipleRewardPool, RolesManager, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public rewardsDuration = 12 hours;
    uint256 private _totalSupply;
    address public immutable stakingToken;
    address public poolRewardDistributor;
    address public seniorage;
    
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => uint256) public lastUpdateTimePerToken;
    mapping(address => uint256) public periodFinishPerToken;
    mapping(address => uint256) public rewardRates;
    mapping(address => uint256) public userLastDepositTime;
    mapping(address => uint256) internal _balances;
    EnumerableSet.AddressSet internal _rewardTokens;

    event RewardAdded(address indexed rewardToken, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed rewardToken, address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event PoolRewardDistributorUpdated(address indexed poolRewardDistributor);
    event SeniorageUpdated(address indexed seniorage);
    
    modifier onlyPoolRewardDistributor {
        require(
            msg.sender == poolRewardDistributor,
            "MultipleRewardPool: caller is not the PoolRewardDistributor contract"
        );
        _;
    }
    
    modifier onlyValidToken(address rewardToken_) {
        require(
            _rewardTokens.contains(rewardToken_),
            "MultipleRewardPool: invalid token"
        );
        _;
    }
    
    modifier updateReward(address user_) {
        _updateAllRewards(user_);
        _;
    }
    
    modifier updateRewardPerToken(address rewardToken_, address user_) {
        _updateReward(rewardToken_, user_);
        _;
    }
    
    /**
    * @param stakingToken_ Staking token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    * @param rewardTokens_ Reward token addresses.
    */
    constructor(
        address stakingToken_,
        address poolRewardDistributor_,
        address seniorage_,
        address[] memory rewardTokens_
    ) {
        stakingToken = stakingToken_;
        poolRewardDistributor = poolRewardDistributor_;
        seniorage = seniorage_;
        for (uint256 i = 0; i < rewardTokens_.length; i++) {
            _rewardTokens.add(rewardTokens_[i]);
        }
    }
    
    /**
    * @notice Sets the PoolRewardDistributor contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    */
    function setPoolRewardDistributor(address poolRewardDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        poolRewardDistributor = poolRewardDistributor_;
        emit PoolRewardDistributorUpdated(poolRewardDistributor_);
    }
    
    /**
    * @notice Sets the Seniorage contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param seniorage_ Seniorage contract address.
    */
    function setSeniorage(address seniorage_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        seniorage = seniorage_;
        emit SeniorageUpdated(seniorage_);
    }
    
    /**
    * @notice Sets rewards duration.
    * @dev Could be called only by the owner.
    * @param rewardsDuration_ New rewards duration value.
    */
    function setRewardsDuration(uint256 rewardsDuration_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool finished = true;
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            if (block.timestamp <= periodFinishPerToken[_rewardTokens.at(i)]) {
                finished = false;
            }
            require(
                finished, 
                "MultipleRewardPool: duration cannot be changed now"
            );
        }
        rewardsDuration = rewardsDuration_;
        emit RewardsDurationUpdated(rewardsDuration_);
    }
    
    /**
    * @notice Deposits tokens for the user.
    * @dev Updates user's last deposit time. The deposit amount of tokens cannot be equal to 0.
    * @param amount_ Amount of tokens to deposit.
    */
    function stake(
        uint256 amount_
    ) 
        external 
        virtual
        whenNotPaused
        nonReentrant 
        updateReward(msg.sender) 
    {
        require(
            amount_ > 0, 
            "MultipleRewardPool: can not stake 0"
        );
        _totalSupply += amount_;
        _balances[msg.sender] += amount_;
        userLastDepositTime[msg.sender] = block.timestamp;
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount_);
        emit Staked(msg.sender, amount_);
    }
    
    /**
    * @notice Withdraws all tokens deposited by the user and gets rewards for him.
    * @dev Withdrawal comission is the same as for the `withdraw()` function.
    */
    function exit() external whenNotPaused {
        withdraw(getBalance(msg.sender));
        getReward();
    }
    
    /**
    * @notice Notifies the contract of an incoming reward in one of the reward tokens 
    * and recalculates the reward rate.
    * @dev Called by the PoolRewardDistributor contract once every 12 hours.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param reward_ Reward amount.
    */
    function notifyRewardAmount(
        address rewardToken_,
        uint256 reward_
    )
        external
        virtual
        onlyPoolRewardDistributor
        onlyValidToken(rewardToken_)
        updateRewardPerToken(rewardToken_, address(0))
    {
        if (block.timestamp >= periodFinishPerToken[rewardToken_]) {
            rewardRates[rewardToken_] = reward_ / rewardsDuration;
        } else {
            uint256 remaining = periodFinishPerToken[rewardToken_] - block.timestamp;
            uint256 leftover = remaining * rewardRates[rewardToken_];
            rewardRates[rewardToken_] = (reward_ + leftover) / rewardsDuration;
        }
        uint256 balance = IERC20(rewardToken_).balanceOf(address(this));
        require(
            rewardRates[rewardToken_] <= balance / rewardsDuration,
            "MultipleRewardPool: provided reward too high"
        );
        lastUpdateTimePerToken[rewardToken_] = block.timestamp;
        periodFinishPerToken[rewardToken_] = block.timestamp + rewardsDuration;
        emit RewardAdded(rewardToken_, reward_);
    }
    
    /**
    * @notice Retrieves an address of one of the reward tokens by index.
    * @dev The read time complexity is O(1).
    * @param index_ Index value.
    * @return Address of one of the reward tokens.
    */
    function getRewardToken(uint256 index_) external view returns (address) {
        return _rewardTokens.at(index_);
    }
    
    /**
    * @notice Retrieves the number of reward tokens.
    * @dev Utilized with `getRewardToken()` function to retrieve all the addresses properly.
    * @return Number of reward tokens.
    */
    function getRewardTokensCount() external view returns (uint256) {
        return _rewardTokens.length();
    }
    
    /**
    * @notice Retrieves the total reward amount for duration in one of the reward tokens.
    * @dev The function allows to get the amount of reward to be distributed in the current period.
    * @param rewardToken_ Address of one of the reward tokens.
    * @return Total reward amount for duration.
    */
    function getRewardForDuration(
        address rewardToken_
    )
        external
        view
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        return rewardRates[rewardToken_] * rewardsDuration;
    }

    /**
    * @notice Retrieves the potential reward amount in one
    * of the reward tokens for duration.
    * @dev Reward rate may change, so this function is not completely accurate.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param user_ User address.
    * @param duration_ Arbitrary time interval in seconds.
    * @return Potential reward amount in one of the reward tokens for given duration.
    */
    function calculatePotentialReward(
        address rewardToken_,
        address user_,
        uint256 duration_
    )
        external
        view
        virtual
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        return
            getBalance(user_)
            * (_rewardPerTokenForDuration(rewardToken_, duration_)
            - userRewardPerTokenPaid[rewardToken_][user_])
            / 1e18
            + rewards[user_][rewardToken_];
    }

    /**
    * @notice Withdraws the desired amount of deposited tokens for the user.
    * @dev If 24 hours have not passed since the last deposit by the user, 
    * a fee of 50% is charged from the withdrawn amount of deposited tokens
    * and sent to the Seniorage contract, otherwise a 10% fee will be charged and sent 
    * to the Seniorage contract as well. The withdrawn amount of tokens cannot
    * exceed the amount of the deposit or be equal to 0.
    * @param amount_ Desired amount of tokens to withdraw.
    */
    function withdraw(
        uint256 amount_
    )
        public
        virtual
        whenNotPaused
        nonReentrant
        updateReward(msg.sender)
    {
        require(
            amount_ > 0, 
            "MultipleRewardPool: can not withdraw 0"
        );
        _totalSupply -= amount_;
        _balances[msg.sender] -= amount_;
        uint256 seniorageFeeAmount;
        if (block.timestamp < userLastDepositTime[msg.sender] + 1 days) {
            seniorageFeeAmount = amount_ / 2;
        } else {
            seniorageFeeAmount = amount_ / 10;
        }
        IERC20(stakingToken).safeTransfer(seniorage, seniorageFeeAmount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount_ - seniorageFeeAmount);
        emit Withdrawn(msg.sender, amount_ - seniorageFeeAmount);
    }
    
    /**
    * @notice Transfers rewards to the user.
    * @dev There are no fees on the reward.
    */
    function getReward(
    ) 
        public 
        virtual 
        whenNotPaused
        nonReentrant 
        updateReward(msg.sender) 
    {
        _getReward();
    }

    /**
    * @notice Retrieves the user's deposit.
    * @dev The function is virtual since the SnacksPool contract implements its own behaviour.
    * @param user_ User address.
    * @return Amount of the deposit.
    */
    function getBalance(address user_) public virtual view returns (uint256) {
        return _balances[user_];
    }

    /**
    * @notice Retrieves a total amount of deposited tokens.
    * @dev The function is virtual since the SnacksPool contract implements its own behaviour.
    * @return Total amount of deposited tokens.
    */
    function getTotalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
    * @notice Retrieves the time a reward was applicable for one of the reward tokens.
    * @dev Allows the contract to correctly calculate rewards earned by users.
    * @param rewardToken_ Address of one of the reward tokens.
    * @return Last time reward was applicable for one of the reward tokens.
    */
    function lastTimeRewardApplicable(
        address rewardToken_
    )
        public
        view
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        return
            block.timestamp < periodFinishPerToken[rewardToken_]
            ? block.timestamp
            : periodFinishPerToken[rewardToken_];
    }
    
    /**
    * @notice Retrieves the amount of reward per token 
    * staked in one of the reward tokens.
    * @dev The logic is derived from the StakingRewards contract.
    * @param rewardToken_ Address of one of the reward tokens.
    * @return Amount of reward per token staked in one of the reward tokens.
    */
    function rewardPerToken(
        address rewardToken_
    )
        public
        view
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        uint256 totalSupply = getTotalSupply();
        if (totalSupply == 0) {
            return rewardPerTokenStored[rewardToken_];
        }
        return
            (lastTimeRewardApplicable(rewardToken_) - lastUpdateTimePerToken[rewardToken_])
            * rewardRates[rewardToken_]
            * 1e18
            / totalSupply
            + rewardPerTokenStored[rewardToken_];
    }
    
    /**
    * @notice Retrieves the amount of rewards earned 
    * by the user in one of the reward tokens.
    * @dev The logic is derived from the StakingRewards contract.
    * @param user_ User address.
    * @param rewardToken_ Address of one of the reward tokens.
    * @return Amount of rewards earned by the user in one of the reward tokens.
    */
    function earned(
        address user_,
        address rewardToken_
    )
        public
        view
        virtual
        onlyValidToken(rewardToken_)
        returns (uint256)
    {
        return
            getBalance(user_)
            * (rewardPerToken(rewardToken_) - userRewardPerTokenPaid[rewardToken_][user_])
            / 1e18
            + rewards[user_][rewardToken_];
    }

    /**
    * @notice Transfers rewards to the user.
    * @dev This functional was isolated due to internal usage (to avoid `nonReentrant` modifier functionality).
    */ 
    function _getReward() internal {
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            address rewardToken = _rewardTokens.at(i);
            uint256 reward = rewards[msg.sender][rewardToken];
            if (reward > 0) {
                rewards[msg.sender][rewardToken] = 0;
                IERC20(rewardToken).safeTransfer(msg.sender, reward);
                emit RewardPaid(rewardToken, msg.sender, reward);
            }
        }
    }

    /**
    * @notice Updates the reward earned by the user in one of the reward tokens.
    * @dev Called inside `updateRewardPerToken` modifier and `_updateAllRewards()` function.
    * It serves both purpose: gas savings and readability.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param user_ User address.
    */
    function _updateReward(address rewardToken_, address user_) internal virtual {
        rewardPerTokenStored[rewardToken_] = rewardPerToken(rewardToken_);
        lastUpdateTimePerToken[rewardToken_] = lastTimeRewardApplicable(rewardToken_);
        if (user_ != address(0)) {
            rewards[user_][rewardToken_] = earned(user_, rewardToken_);
            userRewardPerTokenPaid[rewardToken_][user_] = rewardPerTokenStored[rewardToken_];
        }
    }

     /**
    * @notice Retrieves the amount of reward per token staked 
    * in one of the reward tokens.
    * @dev Called inside `calculatePotentialReward()` function.
    * @param rewardToken_ Address of one of the reward tokens.
    * @param duration_ Arbitrary time interval in seconds.
    * @return Amount of reward per token staked in one of the reward tokens.
    */
    function _rewardPerTokenForDuration(
        address rewardToken_,
        uint256 duration_
    )
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = getTotalSupply();
        if (totalSupply == 0) {
            return rewardPerTokenStored[rewardToken_];
        }
        return
            duration_
            * rewardRates[rewardToken_]
            * 1e18
            / totalSupply
            + rewardPerTokenStored[rewardToken_];
    }
    
    /**
    * @notice Updates all rewards earned by the user.
    * @dev Called when the user deposits, exits, withdraws or gets his rewards.
    * @param user_ User address.
    */
    function _updateAllRewards(address user_) private {
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            _updateReward(_rewardTokens.at(i), user_);
        }
    }
}