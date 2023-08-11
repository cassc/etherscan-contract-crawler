/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-27
 */

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
            "Ownable: new owner is the zero address"
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Dexi/DexiStake.sol

pragma solidity ^0.8.9;

contract DexiStake is Ownable, ReentrancyGuard {
    address public _rewardTokenAddress =
        0xDF6E5140Cc4d9Cf4F718F314C02fDd90622B31f6;
    address public _stakingTokenAddress =
        0xDF6E5140Cc4d9Cf4F718F314C02fDd90622B31f6;
    address public _dvtTokenAddress =
        0x4f2f245e66D2768B5eC467DD3129B7a32232017D;
    // apr = usdcPerSecondPerUsdc * 365 * 24 * 60 * 60 / 1e6 / 1e8 * 100
    // _usdcPerSecondPerUsdc = (APR)*1e6*1e8/(365*24*60*60*100)
    uint256 public _usdcPerSecondPerUsdc = 317097919837646000; //8 decimals 237823000000000
    uint256 public _lockPeriod = 180 days;

    uint256 public totalDexiAwarded = 0;
    uint256 public totalUsdcAwarded = 0;

    struct UserInfo {
        address user;
        uint256 stakedAmount;
        uint256 rewardAmount;
        uint256 lastOperation;
        uint256 unlockTime;
    }

    mapping(address => UserInfo) public userInfo;

    address[] private users;

    modifier isUnlocked() {
        require(
            userInfo[msg.sender].unlockTime <= block.timestamp,
            "operator: your funds are still locked!"
        );
        _;
    }

    constructor() {}

    function getUnlockingFundsAt(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 result = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (timestamp >= userInfo[users[i]].unlockTime) {
                result += userInfo[users[i]].stakedAmount;
            }
        }
        return result;
    }

    function getStakedFundsAt(uint256 timestamp) public view returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < users.length; i++) {
            result += userInfo[users[i]].stakedAmount;
        }
        return result;
    }

    function getTotalDexiRewardsAt(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 usdcRewards = getTotalUsdcRewardsAt(timestamp);

        uint256 rewardsInDexi = usdcRewards;

        return rewardsInDexi;
    }

    function getTotalUsdcRewardsAt(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 result = 0;
        for (uint256 i = 0; i < users.length; i++) {
            result += getRewardsAt(users[i], timestamp);
        }
        return result;
    }

    function getAllRewardsAt(uint256 timestamp) public view returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < users.length; i++) {
            if (timestamp >= userInfo[users[i]].unlockTime) {
                result += getRewardsAt(users[i], timestamp);
            }
        }
        return result;
    }

    function getNeededDepositForUnlockingFunds(uint256 timestamp)
        public
        view
        returns (uint256, uint256)
    {
        uint256 unlockingFunds = getUnlockingFundsAt(timestamp);
        uint256 stakingTokenBalance = IERC20(_stakingTokenAddress).balanceOf(
            address(this)
        );

        uint256 unlockingRewards = getAllRewardsAt(timestamp);
        uint256 rewardTokenBalance = IERC20(_rewardTokenAddress).balanceOf(
            address(this)
        );

        uint256 rewardsInDexi = unlockingRewards;

        return (
            stakingTokenBalance > unlockingFunds
                ? 0
                : unlockingFunds - stakingTokenBalance,
            rewardTokenBalance > rewardsInDexi
                ? 0
                : rewardsInDexi - rewardTokenBalance
        );
    }

    function getPendingRewards(address user) public view returns (uint256) {
        uint256 pendingRewards = ((block.timestamp -
            userInfo[user].lastOperation) *
            (userInfo[user].stakedAmount) *
            _usdcPerSecondPerUsdc) /
            100000000 /
            1e18;
        return pendingRewards;
    }

    function getRewardsAt(address user, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        if (timestamp <= block.timestamp) {
            return getTotalRewards(user);
        } else {
            uint256 futureRewards = ((((timestamp - block.timestamp) *
                userInfo[user].stakedAmount) / 1e18) * _usdcPerSecondPerUsdc) /
                100000000;
            return getTotalRewards(user) + (futureRewards);
        }
    }

    function getTotalRewards(address user) public view returns (uint256) {
        return userInfo[user].rewardAmount + getPendingRewards(user);
    }

    function getTotalUsers() public view returns (uint256) {
        return users.length;
    }

    function deposit(uint256 amount) public nonReentrant {
        uint256 amountStaked = amount;
        uint256 rewardAmount = 0;
        if (userInfo[msg.sender].user == address(0)) {
            users.push(msg.sender);
        } else {
            amountStaked += userInfo[msg.sender].stakedAmount;
            rewardAmount =
                userInfo[msg.sender].rewardAmount +
                getPendingRewards(msg.sender);
        }
        userInfo[msg.sender] = UserInfo({
            user: msg.sender,
            stakedAmount: amountStaked,
            rewardAmount: rewardAmount,
            lastOperation: block.timestamp,
            unlockTime: block.timestamp + _lockPeriod
        });
        uint256 dexiPerAmount = amount;

        IERC20(_stakingTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        IERC20(_dvtTokenAddress).transfer(msg.sender, amount);
    }

    function withdraw() public isUnlocked nonReentrant {
        userInfo[msg.sender].rewardAmount += getPendingRewards(msg.sender);
        userInfo[msg.sender].lastOperation = block.timestamp;
        userInfo[msg.sender].unlockTime = block.timestamp + _lockPeriod;
        IERC20(_dvtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            userInfo[msg.sender].stakedAmount
        );
        IERC20(_stakingTokenAddress).transfer(
            msg.sender,
            userInfo[msg.sender].stakedAmount
        );

        uint256 rewardsInDexi = userInfo[msg.sender].rewardAmount;

        if (rewardsInDexi > 0) {
            IERC20(_rewardTokenAddress).transfer(msg.sender, rewardsInDexi);
            totalDexiAwarded += rewardsInDexi;
            totalUsdcAwarded += userInfo[msg.sender].rewardAmount;
        }
        userInfo[msg.sender].rewardAmount = 0;
        userInfo[msg.sender].stakedAmount = 0;
    }

    function claim() public isUnlocked nonReentrant {
        userInfo[msg.sender].rewardAmount += getPendingRewards(msg.sender);
        userInfo[msg.sender].lastOperation = block.timestamp;
        userInfo[msg.sender].unlockTime = block.timestamp + _lockPeriod;

        uint256 rewardsInDexi = userInfo[msg.sender].rewardAmount;

        totalDexiAwarded += rewardsInDexi;
        totalUsdcAwarded += userInfo[msg.sender].rewardAmount;
        IERC20(_rewardTokenAddress).transfer(msg.sender, rewardsInDexi);
        userInfo[msg.sender].rewardAmount = 0;
    }

    function getCurrentDexiRewards(address user) public view returns (uint256) {
        uint256 rewardsInDexi = getTotalRewards(user);

        return rewardsInDexi;
    }

    function withdraw(address[] calldata tokenAddresses) public onlyOwner {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20(tokenAddresses[i]).transfer(
                msg.sender,
                IERC20(tokenAddresses[i]).balanceOf(address(this))
            );
        }
    }

    function setRewardTokenAddress(address rewardTokenAddress)
        public
        onlyOwner
    {
        _rewardTokenAddress = rewardTokenAddress;
    }

    function setStakingTokenAddress(address stakingTokenAddress)
        public
        onlyOwner
    {
        _stakingTokenAddress = stakingTokenAddress;
    }

    function setUsdcPerSecondPerUsdc(uint256 usdcPerSecondPerUsdc)
        public
        onlyOwner
    {
        _usdcPerSecondPerUsdc = usdcPerSecondPerUsdc;
    }

    function setLockPeriod(uint256 lockPeriod) public onlyOwner {
        _lockPeriod = lockPeriod;
    }

    function setDVTToken(address tokenAddress) public onlyOwner {
        _dvtTokenAddress = tokenAddress;
    }
}