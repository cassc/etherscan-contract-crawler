/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/elmo_staking.sol


pragma solidity ^0.8.0;





// Stake ELMO and earn rewards while burn :)
contract StakingContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    IERC20 public token;

    struct Staker {
        uint256 amount;      // Amount staked
        uint256 stakeTime;   // When the stake was made
        uint256 reward;      // The reward allocated
        uint256 burnAmount;  // The amount burned
    }

    // A mapping of staker's addresses to their staking information
    mapping(address => Staker) public stakers;

    // The total amount of tokens that have been staked
    uint256 public totalStaked;

    // The total amount of tokens that have been allocated for rewards and burns
    uint256 public totalAllocated;

    // The total amount of tokens burned
    uint256 public totalBurned;

    // The total amount of tokens in the staking pool
    uint256 public stakingPool;

    // Constants for staking period, reward rate, burn rate, and total rate
    uint256 public constant STAKE_PERIOD = 43 days;
    uint256 public constant REWARD_RATE = 3; // percentage
    uint256 public constant BURN_RATE = 7; // percentage
    uint256 public constant TOTAL_RATE = 10; // REWARD_RATE + BURN_RATE

    uint256 public emergencyWithdrawalPenalty = 25; // Penalty in percentage (25%)
    uint256 public burnRateEmergency = 40; // 40% of the penalty (10% of the total)
    uint256 public poolRateEmergency = 60; // 60% of the penalty (15% of the total)

    // Events to provide transparency and traceability
    event Staked(address indexed user, uint256 amount, uint256 reward, uint256 burnAmount);
    event Unstaked(address indexed user, uint256 amount);
    event EmergencyUnstaked(address indexed user, uint256 amount);
    event Burned(uint256 amount);
    // Event to log changes to the emergency rates
    event EmergencyRatesUpdated(uint256 penalty, uint256 burnRate, uint256 poolRate);

    // The constructor takes in the address of the token that will be staked
    constructor(IERC20 _token) {
        token = _token;
    }

    // The owner calls this function to deposit tokens into the staking pool, he can never withdraw what he provides
    function addToStakingPool(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than zero");
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 received = token.balanceOf(address(this)).sub(balanceBefore);

        // Check to make sure the correct amount of tokens were transferred
        assert(received == _amount);

        // Add the received amount to the staking pool
        stakingPool = stakingPool.add(_amount);
    }

    // Users call this function to stake tokens. Their tokens get locked in the contract and rewards are allocated to them from the staking pool.
    // Note: User's staked tokens do not add to the staking pool.
    function stake(uint256 _amount) external nonReentrant {
        // Check if the user is already staking
        require(stakers[msg.sender].amount == 0, "Already staking, you can stake more only after current period ends");

        // Calculate total amount that will be allocated (10% of the staked amount)
        uint256 totalAllocation = _amount.mul(TOTAL_RATE).div(100);

        // Check if staking pool has enough funds for the allocation
        require(stakingPool >= totalAllocation, "Staking pool has not enough funds");

        // Calculate burn amount and reward based on total allocation
        uint256 burnAmount = totalAllocation.mul(BURN_RATE).div(TOTAL_RATE);
        uint256 reward = totalAllocation.mul(REWARD_RATE).div(TOTAL_RATE);

        // Transfer the staking amount from the user to the contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Burn the burn amount immediately from the staking pool
        burn(burnAmount);

        // Update staker's information
        stakers[msg.sender].amount = _amount;
        stakers[msg.sender].stakeTime = block.timestamp;
        stakers[msg.sender].reward = reward;
        stakers[msg.sender].burnAmount = burnAmount;

        // Update total staked and total allocated
        totalStaked = totalStaked.add(_amount);
        totalAllocated = totalAllocated.add(totalAllocation);

        // Subtract the allocated amount from the staking pool
        stakingPool = stakingPool.sub(totalAllocation);

        // Emit Staked event
        emit Staked(msg.sender, _amount, reward, burnAmount);
        emit Burned(burnAmount);
    }

    // Users call this function to unstake their tokens after the staking period has passed and receive their original staked amount plus the reward
    function unstake() external nonReentrant {
        require(stakers[msg.sender].amount > 0, "You don't have any staked amount");
        require(block.timestamp >= stakers[msg.sender].stakeTime + STAKE_PERIOD, "Stake period has not passed");

        uint256 reward = stakers[msg.sender].reward;

        // Transfer the staked amount and the reward to the user
        token.transfer(msg.sender, stakers[msg.sender].amount.add(reward));

        uint256 amount = stakers[msg.sender].amount;
        
        // Update total staked and total allocated
        totalStaked = totalStaked.sub(stakers[msg.sender].amount);
        totalAllocated = totalAllocated.sub(stakers[msg.sender].reward.add(stakers[msg.sender].burnAmount));

        // Reset staker's information
        stakers[msg.sender].amount = 0;
        stakers[msg.sender].stakeTime = 0;
        stakers[msg.sender].reward = 0;
        stakers[msg.sender].burnAmount = 0;

        // Emit Unstaked event
        emit Unstaked(msg.sender, amount);
    }

    // Emergency unstake function with penalty
    function emergencyUnstake() external nonReentrant {
        require(stakers[msg.sender].amount > 0, "You don't have any staked amount");

        uint256 total = stakers[msg.sender].amount.add(stakers[msg.sender].reward);
        uint256 penalty = total.mul(emergencyWithdrawalPenalty).div(100);
        uint256 burnAmount = penalty.mul(burnRateEmergency).div(100);
        uint256 poolAmount = penalty.sub(burnAmount);

        // Transfer the remaining amount after penalty to the user
        token.transfer(msg.sender, total.sub(penalty));

        // Burn the burn amount immediately from the staking pool
        if (burnAmount > 0) {
            burn(burnAmount);
            emit Burned(burnAmount);
        }

        // Add the pool amount back to the staking pool
        stakingPool = stakingPool.add(poolAmount);

        // Update total staked and total allocated
        totalStaked = totalStaked.sub(stakers[msg.sender].amount);
        totalAllocated = totalAllocated.sub(stakers[msg.sender].reward).add(poolAmount);

        // Reset staker's information
        stakers[msg.sender].amount = 0;
        stakers[msg.sender].stakeTime = 0;
        stakers[msg.sender].reward = 0;
        stakers[msg.sender].burnAmount = 0;

        // Emit Unstaked event
        emit EmergencyUnstaked(msg.sender, total);
    }

    // Function for the owner to set the rates
    function setEmergencyWithdrawalRates(uint256 _penalty, uint256 _burnRate, uint256 _poolRate) external onlyOwner {
        require(_penalty <= 25, "Penalty should not be more than 25%");
        require(_burnRate.add(_poolRate) == 100, "Sum of burn and pool rates should be equal to 100");
        emergencyWithdrawalPenalty = _penalty;
        burnRateEmergency = _burnRate;
        poolRateEmergency = _poolRate;
        emit EmergencyRatesUpdated(_penalty, _burnRate, _poolRate);
    }

    function burn(uint256 amount) private {
        // The `publicBurn` function must take one `uint256` argument, which is the 
        // amount to burn, and return a `bool` value, indicating the success or failure of the operation
        (bool success, ) = address(token).call(abi.encodeWithSignature("publicBurn(uint256)", amount));
        require(success, "Burn failed");
        totalBurned = totalBurned.add(amount);
    }

    // Function to check staking details of a specific user
    function getStakeDetails(address _staker) public view returns(uint256 stakedAmount, uint256 burnedAmount, uint256 rewardAmount, uint256 stakeTime) {
        return (stakers[_staker].amount, stakers[_staker].burnAmount, stakers[_staker].reward, stakers[_staker].stakeTime);
    }

    // Function to check the remaining balance of the staking pool
    function getRemainingStakePool() public view returns(uint256) {
        return stakingPool;
    }

    // Function to check total burned amount by all
    function getTotalBurned() public view returns(uint256) {
        return totalBurned;
    }
}