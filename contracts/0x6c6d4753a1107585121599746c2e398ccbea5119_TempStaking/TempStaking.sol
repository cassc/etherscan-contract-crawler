/**
 *Submitted for verification at Etherscan.io on 2023-10-11
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

/// Implements Ownable with a two step transfer of ownership
interface IOwnable {
    /**
     * @dev Change of ownership proposed.
     * @param currentOwner The current owner.
     * @param proposedOwner The proposed owner.
     */
    event OwnershipProposed(address indexed currentOwner, address indexed proposedOwner);

    /**
     * @dev Ownership transferred.
     * @param previousOwner The previous owner.
     * @param newOwner The new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() external;
}

/// Implements Ownable with a two step transfer of ownership
abstract contract Ownable is IOwnable {
    address private _owner;
    address private _proposedOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Proposes a transfer of ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _proposedOwner = newOwner;
        emit OwnershipProposed(_owner, _proposedOwner);
    }

    /**
     * @dev Accepts ownership of the contract by a proposed account.
     * Can only be called by the proposed owner.
     */
    function acceptOwnership() public virtual override {
        require(msg.sender == _proposedOwner, "Ownable: Only proposed owner can accept ownership");
        _setOwner(_proposedOwner);
        _proposedOwner = address(0);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @dev Fixed Point decimal math utils for variable decimal point precision
///      on 256-bit wide numbers
library Fixed256xVar {
    /// @dev Multiplies two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a * b
    function mulfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * b) / one;
    }

    /// @dev Divides two variable precision fixed point decimal numbers
    /// @param one 1.0 expressed in the base precision of `a` and `b`
    /// @return result = a / b
    function divfV(
        uint256 a,
        uint256 b,
        uint256 one
    ) internal pure returns (uint256) {
        // result is always truncated
        return (a * one) / b;
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20Vesting {
    /// @dev Vesting Terms for ERC tokens
    struct VestingTerms {
        /// @dev startTime for vesting
        uint256 startTime;
        /// @dev vesting Period
        uint256 period;
        /// @dev time after which tokens will be claimable, acts as a vesting clif
        uint256 firstClaimableAt;
        /// @dev total amount of tokens to vest over period
        uint256 amount;
        /// @dev how much was claimed so far
        uint256 claimed;
    }

    /// A new vesting receiver was added.
    event VestingAdded(address indexed receiver, VestingTerms terms);

    /// An existing vesting receiver was removed.
    event VestingRemoved(address indexed receiver);

    /// An existing vesting receiver's address has changed.
    event VestingTransferred(address indexed oldReceiver, address newReceiver);

    /// Some portion of the available amount was claimed by the vesting receiver.
    event VestingClaimed(address indexed receiver, uint256 value);

    /// @return Address of account that starts and stops vesting for different parties
    function wallet() external view returns (address);

    /// @return Address of token that is being vested
    function token() external view returns (IERC20);

    /// @dev Returns terms on which particular reciever is getting vested tokens
    /// @param receiver Address of beneficiary
    /// @return Vesting terms of particular receiver
    function getVestingTerms(address receiver) external view returns (VestingTerms memory);

    /// @dev Adds new account for vesting
    /// @param receiver Beneficiary for vesting tokens
    /// @param terms Vesting terms for particular receiver
    function startVesting(address receiver, VestingTerms calldata terms) external;

    /// @dev Adds multiple accounts for vesting
    /// Arrays need to be of same length
    /// @param receivers Beneficiaries for vesting tokens
    /// @param terms Vesting terms for all accounts
    function startVestingBatch(address[] calldata receivers, VestingTerms[] calldata terms) external;

    /// @dev Transfers all vested tokens to the sender
    function claim() external;

    /// @dev Transfers a part of vested tokens to the sender
    /// @param value Number of tokens to claim
    ///              The special value type(uint256).max will try to claim all available tokens
    function claim(uint256 value) external;

    /// @dev Transfers vesting schedule from `msg.sender` to new address
    /// A receiver cannot have an existing vesting schedule.
    /// @param oldAddress Address for current token receiver
    /// @param newAddress Address for new token receiver
    function transferVesting(address oldAddress, address newAddress) external;

    /// @dev Stops vesting for receiver and sends unvested tokens back to wallet
    /// Any earned claimable amount is still claimable through `claim()`.
    /// Note that the account cannot be used again as the vesting receiver.
    /// @param receiver Address of account for which we are stopping vesting
    function stopVesting(address receiver) external;

    /// @dev Calculates the maximum amount of vested tokens that can be claimed for particular address
    /// @param receiver Address of token receiver
    /// @return Number of vested tokens one can claim
    function claimable(address receiver) external view returns (uint256);
}

interface IVestingFactory {
    /// @notice Event emitted on successful vesting contract deployment
    /// @param vestingContract The vesting contract
    event VestingContractDeployed(IERC20Vesting vestingContract);

    /// @notice Deploys a new vesting contract
    /// @param tokenToBeVested The token that the contract is going to vest
    /// @return The deployed contract
    function deployVestingContract(IERC20 tokenToBeVested) external returns (IERC20Vesting);
}

/// @title The interface for a staking smart contract
interface ITempStaking is IOwnable {
    /// @notice Event emitted on successful staking
    /// @param staker The address of the wallet that is staking
    /// @param positionId The newly created position ID
    /// @param amount The amount being staked
    event Staked(address indexed staker, uint256 indexed positionId, uint256 amount);

    /// @notice Event emitted on successful withdraw
    /// @param staker The address of the wallet that is withdrawing
    /// @param positionId The withdrawn position ID
    /// @param amount The amount being withdrawn
    event Withdrawn(address indexed staker, uint256 indexed positionId, uint256 amount);

    /// @notice Event emitted on successful start of reward vesting
    /// @param staker The address of the wallet that is getting reward vesting
    /// @param positionId The position ID for which vesting has started
    /// @param token The reward token
    /// @param owedBaseReward The amount of base reward accrued
    /// @param rewardWithMultiplier The base reward accrued with applied multiplier - this is the actual reward that is going to be vested
    event RewardVestingStarted(
        address indexed staker,
        uint256 indexed positionId,
        IERC20 indexed token,
        uint256 owedBaseReward,
        uint256 rewardWithMultiplier
    );

    /// @notice Event emitted on successful payment of reward tokens
    /// @param staker The address of the wallet that is getting paid
    /// @param positionId The position ID for which rewards were claimed
    /// @param token The reward token
    /// @param owedBaseReward The amount of base reward accrued
    /// @param rewardWithMultiplier The base reward accrued with applied multiplier - this is the actual reward that is going to be paid
    event RewardPaid(
        address indexed staker,
        uint256 indexed positionId,
        IERC20 indexed token,
        uint256 owedBaseReward,
        uint256 rewardWithMultiplier
    );

    /// @notice Event emitted on successful registration of a reward token
    /// @param token The reward token
    event RewardTokenRegistered(IERC20 indexed token);

    /// @notice Event emitted on successful update of the amount of reward tokens to distribute to stakers per second
    /// @param token The reward token
    /// @param rewardPerSecond The new amount of reward tokens to distribute to stakers per second
    event RewardPerSecondUpdated(IERC20 indexed token, uint256 rewardPerSecond);

    /// @notice Error thrown when the address of the staking token is zero
    error ZeroAddressStakingToken();

    /// @notice Error thrown when the address of the vesting factory contract is zero
    error ZeroAddressVestingFactory();

    /// @notice Error thrown when the timeMultiplierIncreasePerSecond is zero
    error ZeroTimeMultiplierIncreasePerSecond();

    /// @notice Error thrown when the token amount supplied to a reward program is zero
    error ZeroRewardTokensSuppliedAmount();

    /// @notice Error thrown when the token decimals are not 18
    error Only18DecimalsTokensSupported();

    /// @notice Error thrown when adding a reward program with a zero duration
    error ZeroRewardProgramDuration();

    /// @notice Error thrown when the reward per second for a reward program is less than the minimum allowed
    error RewardPerSecondTooSmall(uint256 providedRewardPerSecond, uint256 minimumAllowedRewardPerSecond);

    /// @notice Error thrown when the cliff of a vesting is bigger than the vesting period
    /// @param cliff Cliff period of vesting
    /// @param period Period for vesting
    error IncorrectRewardProgramVestingConfiguration(uint256 cliff, uint256 period);

    /// @notice Error thrown when the vesting cliff is bigger than the maximum allowed
    error VestingCliffTooBig(uint256 providedCliff, uint256 maximumAllowedCliff);

    /// @notice Error thrown when the vesting period is bigger than the maximum allowed
    error VestingPeriodTooBig(uint256 providedPeriod, uint256 maximumAllowedPeriod);

    /// @notice Error thrown when reward token has already been registered
    error RewardTokenAlreadyRegistered();

    /// @notice Error thrown when reward token has not been registered yet
    error RewardTokenNotRegisteredYet();

    /// @notice Error thrown when trying to perform an operation on a reward program that is already finished
    error RewardProgramFinished();

    /// @notice Error thrown when trying to add a reward program and providing an insufficient amount of tokens
    /// @param requiredAmount The amount of reward tokens required.
    error InsufficientRewardAmount(uint256 requiredAmount);

    /// @notice Error thrown when trying to withdraw rewards before a reward program is finished, or before
    /// the reward claim grace period has passed
    error TooEarlyToClaimLeftoverRewards();

    /// @notice Error thrown when the given stake amount is zero
    error ZeroStakeAmount();

    /// @notice Error thrown when a user tries to stake but there is no reward program available yet
    error NoRewardProgramAvailable();

    /// @notice Error thrown when the given withdraw amount is zero
    error ZeroWithdrawAmount();

    /// @notice Holds information about a staking position of a wallet
    /// @param startTimestamp The timestamp of start of the staking position
    /// @param balance The amount of tokens being staked
    struct StakingPosition {
        uint256 startTimestamp;
        uint256 balance;
    }

    /// @notice Holds information about a reward token program
    /// @param rewardPerSecond The amount of reward tokens to distribute to stakers per second
    /// @param lastRewardPerTokenCached The last cached value for reward rate per second
    /// @param lastUpdateTime The last time the reward data was updated
    /// @param finishTime The timestmap at which the reward program started
    /// @param finishTime The timestmap at which the reward program ends
    /// @param rewardToBePaid The reward tokens due for payment to a given wallet
    /// @param userRewardPerTokenPaid The reward tokens already paid to a given wallet
    struct RewardProgram {
        uint256 rewardPerSecond;
        uint256 lastRewardPerTokenCached;
        uint256 lastUpdateTime;
        uint256 startTime;
        uint256 finishTime;
        mapping(address => mapping(uint256 => uint256)) rewardToBePaid;
        mapping(address => mapping(uint256 => uint256)) userRewardPerTokenPaid;
    }

    /// @notice Holds information about vesting data for reward program
    /// @param vestingContract The vesting contract
    /// @param cliff Cliff period of vesting - sort of lockup period
    /// @param period Period for vesting
    struct VestingData {
        IERC20Vesting vestingContract;
        uint256 cliff;
        uint256 period;
    }

    /// @notice Returns the token that is being staked
    /// @dev Automatically generated getter
    /// @return The token that is being staked
    function stakingToken() external view returns (IERC20);

    /// @dev Automatically generated getter
    /// @return The time multiplier increase per second
    function timeMultiplierIncreasePerSec() external view returns (uint256);

    /// @notice Returns the vesting factory contract
    /// @dev Automatically generated getter
    /// @return The vesting factory contract
    function vestingFactory() external view returns (IVestingFactory);

    /// @notice Returns the total staked tokens supply
    /// @dev Automatically generated getter
    /// @return The total amount of staked tokens
    function totalStakedSupply() external view returns (uint256);

    /// @notice Returns a staking position for a given staker
    /// @dev Automatically generated getter
    /// @param staker The staker whose position to get
    /// @return Staking position data
    function stakingPositions(address staker, uint256 stakingPositionId) external view returns (uint256, uint256);

    /// @notice Returns the next position ID for a given staker
    /// @dev Automatically generated getter
    /// @param staker The staker whose next position ID to get
    /// @return The next position ID
    function nextPositionId(address staker) external view returns (uint256);

    /// @notice Returns the reward token with a given index
    /// @dev Automatically generated getter
    /// @param index The index of the reward token in the array
    /// @return The reward token with a given index
    function rewardTokens(uint256 index) external view returns (IERC20);

    /// @notice Returns vesting information for reward program
    /// @param rewardToken The token for which to get the reward program data
    /// @return vestingData Vesting information including contract, cliff, and period
    function rewardVesting(IERC20 rewardToken)
        external
        view
        returns (
            IERC20Vesting,
            uint256,
            uint256
        );

    /// @notice Returns the reward program data for a given token
    /// @dev Automatically generated getter
    /// @param rewardToken The token for which to get the reward program data
    /// @return Reward Program data
    function rewardPrograms(IERC20 rewardToken)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /// @notice Adds a reward program
    /// @param rewardToken The token of the reward program
    /// @param suppliedAmount The amount of reward tokens to supply
    /// @param rewardPerSecond The amount of reward tokens to distribute to stakers per second
    /// @param rewardProgramDuration The reward program duration
    function addRewardProgram(
        IERC20Metadata rewardToken,
        uint256 suppliedAmount,
        uint256 rewardPerSecond,
        uint256 rewardProgramDuration
    ) external;

    /// @notice Sets the flag that decides if rewards for the program should be vested over a time period
    /// @param rewardToken The reward token that will enable/disable vesting for
    /// @param cliff Cliff period of vesting - sort of lockup period
    /// @param period Period for vesting
    function enableRewardProgramVesting(
        IERC20 rewardToken,
        uint256 cliff,
        uint256 period
    ) external;

    /// @notice Sets the amount of reward tokens to distribute to stakers per second
    /// @param rewardToken The reward token that is being configured
    /// @param rewardPerSecond The new amount of reward tokens to distribute to stakers per second
    function setRewardPerSecond(IERC20 rewardToken, uint256 rewardPerSecond) external;

    /// @notice Recovers any leftover rewards after a reward program has finished and the grace period has passed
    /// @dev Can only be invoked by the contract owner
    /// @param rewardToken The reward program token.
    function withdrawLeftoverRewards(IERC20 rewardToken) external;

    /// @notice Stakes tokens into contract
    /// @param amount The amount of tokens to stake
    /// @return positionId The new staking position's ID
    function stake(uint256 amount) external returns (uint256 positionId);

    /// @notice Withdraws staked tokens from contract and claims all rewards
    /// @param stakingPositionId The staking position ID
    /// @param amountToWithdraw The amount of staked tokens to withdraw
    /// @param shouldClaimRewards A flag to show if you want to claim rewards when withdrawing
    function withdraw(
        uint256 stakingPositionId,
        uint256 amountToWithdraw,
        bool shouldClaimRewards
    ) external;

    /// @notice Claims all rewards for a staking position
    /// @param stakingPositionId The staking position ID
    /// @return The amount of each reward claimed
    function claimRewards(uint256 stakingPositionId) external returns (uint256[] memory);

    /// @notice Calculates claimable rewards for a staker's position
    /// @param staker The staker for which to calculate claimable rewards
    /// @param stakingPositionId The staking position's id for which to calculate claimable rewards
    /// @return The claimable amount of each reward token
    function calculateRewards(address staker, uint256 stakingPositionId) external view returns (uint256[] memory);
}

contract TempStaking is ITempStaking, Ownable {
    using Fixed256xVar for uint256;

    IERC20 public immutable override stakingToken;
    uint256 public immutable override timeMultiplierIncreasePerSec;
    IVestingFactory public immutable override vestingFactory;
    uint256 public override totalStakedSupply;

    mapping(address => mapping(uint256 => StakingPosition)) public override stakingPositions;
    mapping(address => uint256) public override nextPositionId;
    IERC20[] public override rewardTokens;
    mapping(IERC20 => RewardProgram) public override rewardPrograms;
    mapping(IERC20 => VestingData) public override rewardVesting;

    uint256 private constant WAD = 1e18;
    uint256 private constant MAX_VESTING_CLIFF = 365 days;
    uint256 private constant MAX_VESTING_PERIOD = 1825 days; // 5 years
    uint256 private constant MIN_REWARD_PER_SECOND = 1e14; // 1/10000 token
    uint256 private constant REWARD_CLAIM_GRACE_PERIOD = 60 days;

    modifier onlyRegisteredRewardToken(IERC20 rewardToken) {
        if (rewardPrograms[rewardToken].rewardPerSecond == 0) {
            revert RewardTokenNotRegisteredYet();
        }
        _;
    }

    constructor(
        IERC20 _stakingToken,
        IVestingFactory _vestingFactory,
        uint256 _timeMultiplierIncreasePerSec
    ) {
        if (address(_stakingToken) == address(0)) {
            revert ZeroAddressStakingToken();
        }
        if (address(_vestingFactory) == address(0)) {
            revert ZeroAddressVestingFactory();
        }
        if (_timeMultiplierIncreasePerSec == 0) {
            revert ZeroTimeMultiplierIncreasePerSecond();
        }

        stakingToken = _stakingToken;
        vestingFactory = _vestingFactory;
        timeMultiplierIncreasePerSec = _timeMultiplierIncreasePerSec;
    }

    function addRewardProgram(
        IERC20Metadata rewardToken,
        uint256 suppliedAmount,
        uint256 rewardPerSecond,
        uint256 rewardProgramDuration
    ) external override onlyOwner {
        if (suppliedAmount == 0) {
            revert ZeroRewardTokensSuppliedAmount();
        }
        if (rewardToken.decimals() != 18) {
            revert Only18DecimalsTokensSupported();
        }
        if (rewardProgramDuration == 0) {
            revert ZeroRewardProgramDuration();
        }

        _registerRewardToken(rewardToken);
        _setRewardPerSecond(rewardToken, rewardPerSecond);

        uint256 maxTimeMultiplier = WAD + rewardProgramDuration * timeMultiplierIncreasePerSec;
        /// This is the **maximum amount** that can possibly be distributed. It will only be distributed entirely if the
        /// average time multiplier of all stakers is max.
        uint256 requiredAmount = (rewardProgramDuration * rewardPerSecond).mulfV(maxTimeMultiplier, 1e18);
        if (suppliedAmount != requiredAmount) {
            revert InsufficientRewardAmount(requiredAmount);
        }

        RewardProgram storage rewardProgram = rewardPrograms[rewardToken];
        rewardProgram.startTime = block.timestamp;
        rewardProgram.finishTime = block.timestamp + rewardProgramDuration;

        rewardToken.transferFrom(msg.sender, address(this), suppliedAmount);
    }

    function _registerRewardToken(IERC20 rewardToken) private {
        for (uint256 i; i < rewardTokens.length; ++i) {
            if (address(rewardTokens[i]) == address(rewardToken)) {
                revert RewardTokenAlreadyRegistered();
            }
        }

        rewardTokens.push(rewardToken);
        emit RewardTokenRegistered(rewardToken);
    }

    function setRewardPerSecond(IERC20 rewardToken, uint256 rewardPerSecond)
        external
        override
        onlyOwner
        onlyRegisteredRewardToken(rewardToken)
    {
        if (block.timestamp > rewardPrograms[rewardToken].finishTime) {
            revert RewardProgramFinished();
        }

        _setRewardPerSecond(rewardToken, rewardPerSecond);
    }

    function withdrawLeftoverRewards(IERC20 rewardToken)
        external
        override
        onlyOwner
        onlyRegisteredRewardToken(rewardToken)
    {
        if (block.timestamp < rewardPrograms[rewardToken].finishTime + REWARD_CLAIM_GRACE_PERIOD) {
            revert TooEarlyToClaimLeftoverRewards();
        }

        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function _setRewardPerSecond(IERC20 rewardToken, uint256 rewardPerSecond) private {
        if (rewardPerSecond < MIN_REWARD_PER_SECOND) {
            revert RewardPerSecondTooSmall(rewardPerSecond, MIN_REWARD_PER_SECOND);
        }

        RewardProgram storage rewardProgram = rewardPrograms[rewardToken];

        rewardProgram.lastRewardPerTokenCached = rewardPerToken(rewardToken); // this computes to 0 when the call to this method is from `addRewardProgram()`
        rewardProgram.lastUpdateTime = block.timestamp;
        rewardProgram.rewardPerSecond = rewardPerSecond;
        emit RewardPerSecondUpdated(rewardToken, rewardPerSecond);
    }

    function enableRewardProgramVesting(
        IERC20 rewardToken,
        uint256 cliff,
        uint256 period
    ) external override onlyOwner onlyRegisteredRewardToken(rewardToken) {
        if (cliff > period) {
            revert IncorrectRewardProgramVestingConfiguration(cliff, period);
        }
        if (cliff > MAX_VESTING_CLIFF) {
            revert VestingCliffTooBig(cliff, MAX_VESTING_CLIFF);
        }
        if (period > MAX_VESTING_PERIOD) {
            revert VestingPeriodTooBig(period, MAX_VESTING_PERIOD);
        }

        VestingData storage vestingData = rewardVesting[rewardToken];
        if (address(vestingData.vestingContract) == address(0)) {
            vestingData.vestingContract = vestingFactory.deployVestingContract(rewardToken);

            rewardToken.approve(address(vestingData.vestingContract), type(uint256).max);
        }

        vestingData.cliff = cliff;
        vestingData.period = period;
    }

    function rewardPerToken(IERC20 rewardToken) private view returns (uint256) {
        RewardProgram storage rewardProgram = rewardPrograms[rewardToken];
        if (totalStakedSupply == 0) {
            return rewardProgram.lastRewardPerTokenCached;
        }

        uint256 lastApplicableTimestamp = Math.min(rewardProgram.finishTime, block.timestamp);
        uint256 elapsedTime = lastApplicableTimestamp - rewardProgram.lastUpdateTime;
        // The current reward per token is basically the reward up to now plus:
        // calculate the elapsed time and multiply it by the reward rate. Then divide buy the total staked supply
        // so we calculate how much of the reward per second should 1 staked token get.
        return
            rewardProgram.lastRewardPerTokenCached +
            (rewardProgram.rewardPerSecond * elapsedTime).divfV(totalStakedSupply, 1e18); // expect 18 decimals, reward tokens are owner controlled
    }

    function stake(uint256 amount) external override returns (uint256 positionId) {
        if (amount == 0) {
            revert ZeroStakeAmount();
        }
        if (rewardTokens.length == 0) {
            revert NoRewardProgramAvailable();
        }
        positionId = nextPositionId[msg.sender]++;
        updateRewardPrograms(positionId);

        StakingPosition storage stakingPosition = stakingPositions[msg.sender][positionId];

        stakingPosition.startTimestamp = block.timestamp;
        stakingPosition.balance = amount;
        totalStakedSupply += amount;

        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, positionId, amount);
    }

    function withdraw(
        uint256 stakingPositionId,
        uint256 amountToWithdraw,
        bool shouldClaimRewards
    ) external override {
        if (amountToWithdraw == 0) {
            revert ZeroWithdrawAmount();
        }
        updateRewardPrograms(stakingPositionId);

        if (shouldClaimRewards) {
            _claimRewards(stakingPositionId);
        }

        StakingPosition storage stakingPosition = stakingPositions[msg.sender][stakingPositionId];
        stakingPosition.balance -= amountToWithdraw;
        totalStakedSupply -= amountToWithdraw;

        stakingPosition.startTimestamp = block.timestamp;

        stakingToken.transfer(msg.sender, amountToWithdraw);
        emit Withdrawn(msg.sender, stakingPositionId, amountToWithdraw);
    }

    function claimRewards(uint256 stakingPositionId) external override returns (uint256[] memory) {
        updateRewardPrograms(stakingPositionId);
        return _claimRewards(stakingPositionId);
    }

    function _claimRewards(uint256 stakingPositionId) private returns (uint256[] memory) {
        uint256[] memory claimedRewards = new uint256[](rewardTokens.length);

        for (uint256 i; i < rewardTokens.length; ++i) {
            IERC20 rewardToken = rewardTokens[i];

            RewardProgram storage rewardProgram = rewardPrograms[rewardToken];

            uint256 owedBaseReward = rewardProgram.rewardToBePaid[msg.sender][stakingPositionId];
            if (owedBaseReward > 0) {
                rewardProgram.rewardToBePaid[msg.sender][stakingPositionId] = 0;

                uint256 rewardWithMultiplier = _calculateRewardWithMultiplier(
                    msg.sender,
                    rewardToken,
                    stakingPositionId,
                    owedBaseReward
                );

                uint256 rewardBalance = rewardToken.balanceOf(address(this));

                if (address(stakingToken) == address(rewardToken)) {
                    rewardBalance -= totalStakedSupply;
                }

                if (rewardBalance < rewardWithMultiplier) {
                    // when there is not enough reward balance then just distribute what is left
                    rewardWithMultiplier = rewardBalance;
                }

                VestingData storage vestingData = rewardVesting[rewardToken];
                if (address(vestingData.vestingContract) != address(0)) {
                    vestingData.vestingContract.startVesting(
                        msg.sender,
                        IERC20Vesting.VestingTerms(
                            block.timestamp,
                            vestingData.period,
                            block.timestamp + vestingData.cliff,
                            rewardWithMultiplier,
                            0
                        )
                    );
                    emit RewardVestingStarted(
                        msg.sender,
                        stakingPositionId,
                        rewardToken,
                        owedBaseReward,
                        rewardWithMultiplier
                    );
                } else {
                    rewardToken.transfer(msg.sender, rewardWithMultiplier);
                    emit RewardPaid(msg.sender, stakingPositionId, rewardToken, owedBaseReward, rewardWithMultiplier);
                }

                claimedRewards[i] = rewardWithMultiplier;
            }
        }
        return claimedRewards;
    }

    function calculateRewards(address staker, uint256 stakingPositionId)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory rewards = new uint256[](rewardTokens.length);

        for (uint256 i; i < rewardTokens.length; ++i) {
            IERC20 rewardToken = rewardTokens[i];

            (, uint256 baseReward) = calculateRewardValues(rewardToken, staker, stakingPositionId);
            uint256 rewardWithMultiplier = _calculateRewardWithMultiplier(
                staker,
                rewardToken,
                stakingPositionId,
                baseReward
            );

            uint256 rewardBalance = rewardToken.balanceOf(address(this));

            if (address(stakingToken) == address(rewardToken)) {
                rewardBalance -= totalStakedSupply;
            }

            if (rewardBalance < rewardWithMultiplier) {
                rewardWithMultiplier = rewardBalance;
            }
            rewards[i] = rewardWithMultiplier;
        }

        return rewards;
    }

    function _calculateRewardWithMultiplier(
        address staker,
        IERC20 rewardToken,
        uint256 stakingPositionId,
        uint256 reward
    ) private view returns (uint256) {
        return reward.mulfV(timeMultiplier(staker, rewardToken, stakingPositionId), WAD);
    }

    function timeMultiplier(
        address staker,
        IERC20 rewardToken,
        uint256 stakingPositionId
    ) private view returns (uint256) {
        RewardProgram storage rewardProgram = rewardPrograms[rewardToken];
        uint256 firstApplicableTimestamp = Math.max(
            rewardProgram.startTime,
            stakingPositions[staker][stakingPositionId].startTimestamp
        );
        uint256 lastApplicableTimestamp = Math.min(rewardProgram.finishTime, block.timestamp);
        if (firstApplicableTimestamp > lastApplicableTimestamp) {
            return WAD;
        }

        return WAD + (lastApplicableTimestamp - firstApplicableTimestamp) * timeMultiplierIncreasePerSec;
    }

    /// @notice Updates each reward program's properties
    /// @dev Should be used on each user state-changing interaction with the contract
    function updateRewardPrograms(uint256 stakingPositionId) private {
        for (uint256 i; i < rewardTokens.length; ++i) {
            IERC20 rewardToken = rewardTokens[i];
            RewardProgram storage rewardProgram = rewardPrograms[rewardToken];

            (uint256 lastRewardPerTokenCached, uint256 baseReward) = calculateRewardValues(
                rewardToken,
                msg.sender,
                stakingPositionId
            );

            rewardProgram.lastRewardPerTokenCached = lastRewardPerTokenCached;
            rewardProgram.lastUpdateTime = Math.min(rewardProgram.finishTime, block.timestamp);
            rewardProgram.rewardToBePaid[msg.sender][stakingPositionId] = baseReward;
            rewardProgram.userRewardPerTokenPaid[msg.sender][stakingPositionId] = lastRewardPerTokenCached;
        }
    }

    function calculateRewardValues(
        IERC20 rewardToken,
        address staker,
        uint256 stakingPositionId
    ) private view returns (uint256 currentRewardPerToken, uint256 baseReward) {
        currentRewardPerToken = rewardPerToken(rewardToken);
        uint256 rewardsPaid = rewardPrograms[rewardToken].userRewardPerTokenPaid[staker][stakingPositionId];
        uint256 balance = stakingPositions[staker][stakingPositionId].balance;

        // To calculate the reward that should be paid to a staker for a staking position we should multiply
        // his balance of staked tokens in the referred position by the amount of reward tokens given out for each
        // staked token but first subtract the already paid reward per token for the position. This is added to the already accrued reward.
        baseReward =
            rewardPrograms[rewardToken].rewardToBePaid[staker][stakingPositionId] +
            (balance).mulfV((currentRewardPerToken - rewardsPaid), 1e18); // expect 18 decimals, reward tokens are owner controlled
    }
}