/**
 *Submitted for verification at Etherscan.io on 2023-07-17
*/

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/interfaces/IPlanetConventionalPool.sol

pragma solidity >=0.4.22 <0.9.0;

interface IPlanetConventionalPool {
    function userTokenStakeInfo(
        address _user
    )
        external
        view
        returns (
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        );

    function userLpStakeInfo(
        address _user
    )
        external
        view
        returns (
            uint256 _lpAmount,
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        );

    function getUserInfo(
        address _user
    )
        external
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            uint256 _totalStakedToken,
            uint256 _totalStakedLp,
            uint256 _totalWithdrawanToken,
            uint256 _totalWithdrawanLp
        );
}

// File: contracts/interfaces/OwnershipManager.sol

pragma solidity >=0.4.22 <0.9.0;

abstract contract OwnershipManager {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            owner() == msg.sender,
            "OwnershipManager: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "OwnershipManager: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/interfaces/IPairInterface.sol

pragma solidity >=0.4.22 <0.9.0;

interface IPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/PlanetStakingPool.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;




/**
 * @notice Token staking pool enables users to stake their tokens,
 *         to earn % APY for providing their tokens to the staking pool.
 */
contract PlanetStakingPool is OwnershipManager {
    struct AccountDetails {
        uint256 stakedTokenAmount; // Stake Fn
        uint256 firstStakedAt; // Stake Fn
        uint256 rewards; // Stake & Unstake Fn
        uint256 stakeEntries; // Stake Fn
    }
    // Tracking of global account level staking details.
    mapping(address => AccountDetails) public accountDetails;

    // Staking Pool token dependency.
    IERC20 public immutable PLANET_TOKEN;

    // Tracking of staking pool details.
    uint256 public totalStakedTokens; // Stake Fn
    uint256 public totalUnstakedTokens; // Unstake Fn
    uint256 public totalUniqueStakers; // Stake Fn
    uint256 public totalRewards; // Stake Fn
    uint256 public totalHarvestedRewards; // Unstake Fn

    uint256 public APY = 50;

    // Staking pool requirements.
    uint256 public startDate = 1689602400;
    uint256 public maximumPoolAmount = 1e29;
    uint256 public remainingPoolAmount = 1e29;
    uint256 public tokensLockinPeriod = 90 days;
    uint256 public allowedStakingPeriod = 7 days;

    // Tracking of banned accounts
    mapping(address => bool) public isBanned;

    // Staking pool reward provisioning distributor endpoint.
    address public rewardVault;

    // Emergency state
    bool public isPaused;

    // Staking pool events to log core functionality.
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Harvested(address indexed staker, uint256 rewards);
    event Banned(address indexed staker, bool isBanned);
    event Paused(bool isPaused);

    modifier onlyIfNotPaused() {
        require(!isPaused, "PlanetStakingPool: all actions are paused");
        _;
    }

    modifier onlyIfNotBanned() {
        require(!isBanned[msg.sender], "PlanetStakingPool: account banned");
        _;
    }

    /**
     * @dev Initialize contract by deploying a staking pool and setting
     *      up external dependencies.
     *
     * @param initialOwner --> The manager of access restricted functionality.
     * @param rewardToken --> The token that will be rewarded for staking in the pool.
     * @param distributor --> The reward distribution endpoint that will do reward provisioning.
     */
    constructor(
        address payable initialOwner,
        address rewardToken,
        address payable distributor
    ) OwnershipManager(initialOwner) {
        PLANET_TOKEN = IERC20(rewardToken);
        rewardVault = distributor;
    }

    /**
     * @notice Update APY
     *
     * @param newAPY --> new APY.
     */
    function UpdatePoolAPY(uint256 newAPY) external onlyOwner {
        require(
            newAPY > 0,
            "PlanetStakingPool: new APY must be greater than zero"
        );
        APY = newAPY;
    }

    /**
     * @notice SeUpdatet the max token staking requirement for all users,
     *         the pool must comply with the max to stake.
     *
     * @param newMaximumPoolAmount --> The maximum token amount for all users.
     */
    function UpdateMaximumPoolAmount(
        uint256 newMaximumPoolAmount
    ) external onlyOwner {
        require(
            newMaximumPoolAmount > 0 &&
                newMaximumPoolAmount >= totalStakedTokens,
            "PlanetStakingPool: new maximum pool amount must be greater than zero"
        );
        maximumPoolAmount = newMaximumPoolAmount;
        remainingPoolAmount = maximumPoolAmount - totalStakedTokens;
    }

    /**
     * @notice Update the pool start date.
     *
     * @param newStartDate --> The start date in seconds.
     */
    function UpdateStartDate(uint256 newStartDate) external onlyOwner {
        require(
            newStartDate > block.timestamp,
            "PlanetStakingPool: start date must be in the future"
        );
        startDate = newStartDate;
    }

    /**
     * @notice Update the allowed staking period.
     *
     * @param newAllowedStakingPeriod --> The allowed staing period period in days.
     */
    function UpdateAllowedStakingPeriod(
        uint256 newAllowedStakingPeriod
    ) external onlyOwner {
        require(
            newAllowedStakingPeriod > 0 &&
                newAllowedStakingPeriod < tokensLockinPeriod,
            "PlanetStakingPool: new allowed staking period must be greater than zero and less than lockin period"
        );
        allowedStakingPeriod = newAllowedStakingPeriod * 1 days;
    }

    /**
     * @notice Update the token staking lockin period.
     *
     * @param newLockinPeriod --> The lockin period in days.
     */
    function UpdateLockinPeriod(uint256 newLockinPeriod) external onlyOwner {
        require(
            newLockinPeriod > allowedStakingPeriod,
            "PlanetStakingPool: new lockin period must be greater than allowed staking period (14 days)"
        );
        tokensLockinPeriod = newLockinPeriod * 1 days;
    }

    /**
     * @notice Update the reward provisioning endpoint,
     *         this should be the distributor that handle rewards.
     *
     * @param newRewardVault --> The new distributor for reward provisioning.
     */
    function UpdateRewardVault(address newRewardVault) external onlyOwner {
        require(
            newRewardVault != address(0),
            "PlanetStakingPool: new reward vault cannot be zero address"
        );
        rewardVault = newRewardVault;
    }

    /**
     * @notice Update restrictions on an account.
     *
     * @param account --> The account to restrict.
     * @param state --> The state of the restriction.
     */
    function UpdateBanState(address account, bool state) external onlyOwner {
        require(
            isBanned[account] != state,
            "PlanetStakingPool: account already in state"
        );
        isBanned[account] = state;
        emit Banned(account, state);
    }

    /**
     * @notice Update the staking pool in a pause.
     *
     * @param state --> The state of the staking pool.
     */
    function UpdatePoolPauseState(bool state) external onlyOwner {
        require(isPaused != state, "PlanetStakingPool: pool already in state");
        isPaused = state;
        emit Paused(state);
    }

    /**
     * @notice Stake tokens to accumulate token rewards,
     *         token reward accumulation is based on the % APY.
     *
     * @param amount --> The amount of tokens that the account wish,
     *         to stake in the staking pool.
     */
    function stake(uint256 amount) external onlyIfNotPaused onlyIfNotBanned {
        address account = msg.sender;

        // Check that the staked amount is greater than zero
        require(
            amount > 0,
            "PlanetStakingPool: staked amount must be greater than zero"
        );

        // Check that staking has started
        require(
            startDate <= block.timestamp,
            "PlanetStakingPool: staking not started"
        );

        // Check that staking has not locked
        require(
            startDate + allowedStakingPeriod >= block.timestamp,
            "PlanetStakingPool: staking period ended"
        );

        // Check that the staked amount does not overflow the pool
        require(
            totalStakedTokens + amount <= maximumPoolAmount,
            "PlanetStakingPool: staking pool overflow"
        );

        // Check if the account is unique (First Stake), if yes then add it to global tracking and capture first staking time.
        if (accountDetails[account].stakedTokenAmount == 0) {
            totalUniqueStakers++;
            accountDetails[account].firstStakedAt = block.timestamp;
        }

        // Transfer the staked amount of tokens to the staking pool.
        require(
            PLANET_TOKEN.transferFrom(account, address(this), amount),
            "PlanetStakingPool: transfer failed"
        );

        // Update global account staking details.
        accountDetails[account].stakeEntries++;
        // accountDetails[account].lastStakedAt = block.timestamp;
        accountDetails[account].stakedTokenAmount += amount;

        // Calculate rewards
        totalRewards -= accountDetails[account].rewards;
        uint256 rewards = calculateTokenReward(account);
        totalRewards += rewards;
        accountDetails[account].rewards = rewards;

        // Update global staking pool details.
        totalStakedTokens += amount;
        remainingPoolAmount -= amount;

        // Log successful activity.
        emit Staked(account, amount);
    }

    /**
     * @notice Unstake tokens to withdraw your position from the staking pools,
     *         available rewards are transferred to the staking account.
     */
    function unstake() external onlyIfNotPaused onlyIfNotBanned {
        require(
            getAllowingUnstakeDate(msg.sender) <= block.timestamp,
            "PlanetStakingPool: can not unstake yet"
        );

        require(
            accountDetails[msg.sender].rewards > 0,
            "PlanetStakingPool: no rewards to harvest"
        );

        uint256 rewards = accountDetails[msg.sender].rewards;
        uint256 stakedAmount = accountDetails[msg.sender].stakedTokenAmount;

        // Delete the account details before making external calls.
        delete accountDetails[msg.sender];

        // Transfer the staked tokens and rewards to the user account.
        require(
            PLANET_TOKEN.transferFrom(rewardVault, msg.sender, rewards),
            "PlanetStakingPool: rewards transfer failed"
        );
        require(
            PLANET_TOKEN.transfer(msg.sender, stakedAmount),
            "PlanetStakingPool: staked tokens transfer failed"
        );

        totalHarvestedRewards += rewards;
        totalUnstakedTokens += stakedAmount;

        // Log successful activity.
        emit Unstaked(msg.sender, stakedAmount);
        emit Harvested(msg.sender, rewards);
    }

    /**
     * @notice Calculate the unsettled rewards for an account from staking
     *         in the pool, rewards that has not been compounded yet.
     *
     * @param account --> The account to use for reward calculation.
     */
    function calculateTokenReward(
        address account
    ) public view returns (uint256 reward) {
        // Calculate the reward rate of an account.
        reward =
            (accountDetails[account].stakedTokenAmount *
                tokensLockinPeriod *
                APY) /
            (365 days * 100.0);
    }

    /**
     * @notice Calculate the current rewards.
     *
     */
    function calculateTokenCurrentReward(
        address account
    ) public view returns (uint256 reward) {
        require(
            accountDetails[account].stakedTokenAmount > 0,
            "PlanetStakingPool: no staked tokens"
        );
        reward =
            (accountDetails[account].stakedTokenAmount *
                (block.timestamp - accountDetails[account].firstStakedAt) *
                APY) /
            (365 days * 100.0);
    }

    /**
     * @notice Calculate the Unstake Date.
     *
     */
    function getAllowingUnstakeDate(
        address account
    ) public view returns (uint256 unstakeDate) {
        unstakeDate =
            accountDetails[account].firstStakedAt +
            tokensLockinPeriod;
    }
}