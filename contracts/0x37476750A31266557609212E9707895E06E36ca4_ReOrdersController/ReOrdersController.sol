/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// 
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// 
interface IMAMMSwapPair {
    function pause() external;
    function unpause() external;
    function setNewReordersController(address _reordersController) external;
    function addLiquidity() external;
    function removeLiquidity(uint amount0, uint amount1) external;
    function sync() external;
    function mintFee() external;
    function pavAllocation(
        uint newMMFRewards0, 
        uint newMMFRewards1, 
        uint newRainyDayFunds, 
        uint newProtocolFees
    ) external;
    function migrate(address to) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function getTiUSDPrice() external view returns (uint256, bool);
    function getMMFFunds() external view returns (uint _mmfFund0, uint _mmfFund1, uint32 _blockTimestampLast);
    function getDepth() external view returns (uint112 _fund0, uint112 _fund1, uint32 _blockTimestampLast);
}

// 
interface ITiUSDToken {
    function mint(address account, uint amount) external;
    function burn(uint amount) external;
    function reorders(address pair, bool isPositive, uint amount) external;
    function setNewCoreController(address _CoreController) external;
    function balanceOf(address account) external view returns (uint256);
}

// 
/// @title The control module of reorders in TiTi Protocol
/// @author TiTi Protocol
/// @notice This module implements and manages the ReOrders function.
/// @dev Only the owner can call the params' update function, and the owner will be transferred to Timelock in the future.
contract ReOrdersController is Ownable, ReentrancyGuard, Pausable {
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice USDC contract address.
    IERC20 public immutable baseToken;

    /// @notice TiUSD contract address.
    ITiUSDToken public immutable tiusdToken;

    /// @notice MAMMSwapPair contract address.
    IMAMMSwapPair public immutable mamm;

    /// @notice MarketMakerFund contract address.
    address public immutable mmf;

    /// @notice Used to manage accumulated rainy day fund.
    address public rainyDayFundVault;

    /// @notice Used to manage accumulated protocol fee.
    address public protocolFeeVault;

    /// @notice The time period that triggers reorders.
    uint256 public duration = 12 hours;

    /// @notice The maximum TiUSD/USDC price spread that triggers reorders.
    int256 public priceDelta = 0.05e18;

    /// @notice PegPrice's precision.
    int256 public constant PRICE_PRECISION = 1e18;

    /// @notice When there is only USDC in the reserve, the peg price is $1. In the future, 
    /// it will be dynamically calculated based on the reserve ratio.
    int256 public constant PEG_PRICE = 1e18;

    /// @notice To normalize USDC and TiUSD units.
    int256 public constant PRECISION_CONV = 1e12;

    /// @notice The balance of TiUSD in MAMMSwapPair recorded during the last reorders.
    int256 public lastFund0;

    /// @notice The balance of USDC in MAMMSwapPair recorded during the last reorders.
    int256 public lastFund1;

    /// @notice Last reorders' timestamp.
    uint256 public lastReordersTime;

    /// @notice Percentage of PAV allocated to MMF participants.
    uint256 public mmfRewardsAllocation = 0.2e18;

    /// @notice Percentage of PAV allocated to rainy day fund.
    uint256 public rainyDayFundAllocation = 0.4e18;

    /// @notice Percentage of PAV allocated to protocol fee.
    uint256 public protocolFeeAllocation = 0.4e18;

    /// @notice Conditions that trigger reorders.
    enum ReOrdersCondition { Period, PriceSpread, MMF }

    /// @notice Emitted when reorders is triggered.
    event ReOrders(ReOrdersCondition reordersCondition, uint pavAmount, uint lastReordersTime);

    /// @notice Emitted when new priceDelta is set.
    event NewPriceDelta(int256 oldPriceDelta, int256 newPriceDelta);

    /// @notice Emitted when new reorders duration is set.
    event NewDuration(uint oldDuration, uint newDuration);

    /// @notice Emitted when new PAV allocation params is set.
    event NewAllocation(
        uint mmfRewardsAllocation, 
        uint rainyDayFundsAllocation, 
        uint protocolFeesAllocation, 
        address rainyDayFundVault, 
        address protocolFeeVault
    );

    constructor(
        ITiUSDToken _tiusdToken,
        IERC20 _baseToken,
        IMAMMSwapPair _mamm,
        address _mmf,
        address _rainyDayFundVault,
        address _protocolFeeVault
    ) {
        tiusdToken = _tiusdToken;
        baseToken = _baseToken;
        mamm = _mamm;
        mmf = _mmf;
        rainyDayFundVault = _rainyDayFundVault;
        protocolFeeVault = _protocolFeeVault;
        lastReordersTime = block.timestamp;
    }

    modifier onlyMMF() {
        require(msg.sender == mmf, "ReOrdersController: Not Matched MMF");
        _;
    }

    /// @notice Set new priceDelta and emit NewPriceDelta event.
    /// @param _priceDelta New price delta.
    function setNewPriceDelta(int256 _priceDelta) external onlyOwner {
        require(_priceDelta != int256(0), "ReOrdersController: Cannot be zero");
        int256 oldPriceDelta = priceDelta;
        priceDelta = _priceDelta;
        emit NewPriceDelta(oldPriceDelta, _priceDelta);
    }

    /// @notice Set new reorders duration and emit NewDuration event.
    /// @param _duration New reorders duration.
    function setNewDuration(uint256 _duration) external onlyOwner {
        require(_duration != uint256(0), "ReOrdersController: Cannot be zero");
        uint oldDuration = duration;
        duration = _duration;
        emit NewDuration(oldDuration, _duration);
    }

    /// @notice Set new PAV allocation params and emit NewAllocation event.
    /// @param _mmfRewardsAllocation Percentage of PAV allocated to MMF participants.
    /// @param _rainyDayFundAllocation Percentage of PAV allocated to rainy day fund.
    /// @param _protocolFeeAllocation Percentage of PAV allocated to protocol fee.
    /// @param _rainyDayFundVault New rainy day fund vault address.
    /// @param _protocolFeeVault New protocol fee vault address.
    function setNewAllocation(
        uint256 _mmfRewardsAllocation, 
        uint256 _rainyDayFundAllocation, 
        uint256 _protocolFeeAllocation,
        address _rainyDayFundVault, 
        address _protocolFeeVault
    ) 
        external 
        onlyOwner
    {
        require(_rainyDayFundVault != address(0), "ReOrdersController: Cannot be address(0)");
        require(_protocolFeeVault != address(0), "ReOrdersController: Cannot be address(0)");

        uint256 totalAllocation = _mmfRewardsAllocation + _rainyDayFundAllocation + _protocolFeeAllocation;

        require(totalAllocation == 1e18, "ReOrdersController: totalAllocation must be 100%");

        mmfRewardsAllocation = _mmfRewardsAllocation;
        rainyDayFundAllocation = _rainyDayFundAllocation;
        protocolFeeAllocation = _protocolFeeAllocation;
        rainyDayFundVault = _rainyDayFundVault;
        protocolFeeVault = _protocolFeeVault;

        emit NewAllocation(
            _mmfRewardsAllocation, 
            _rainyDayFundAllocation, 
            _protocolFeeAllocation, 
            _rainyDayFundVault, 
            _protocolFeeVault
        );
    }

    /// @notice Used by MMF to update the latest MAMM balance after completing liquidity provision or withdrawal.
    function sync() external nonReentrant whenNotPaused onlyMMF {
        (uint256 _newfund0, uint256 _newfund1,)= mamm.getDepth();
        lastFund0 = _newfund0.toInt256();
        lastFund1 = _newfund1.toInt256();
    }

    /// @notice Pause the whole system.
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /// @notice Unpause the whole system.
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    /// @notice Trigger reorders, adjust the TiUSD/USDC price in MAMM, and complete PAV allocation.
    function reorders() external nonReentrant whenNotPaused {
        uint256 nowTime = block.timestamp;
        ReOrdersCondition reordersCondition;
        
        // There are three trigger conditions for ReOrders:
        //      * When there is any update operation in MMF, reorders will be triggered automatically;
        //      * Fixed time period trigger;
        //      * Fixed spread trigger.
        if (msg.sender == mmf) {
            reordersCondition = ReOrdersCondition.MMF;
        } else if (nowTime >= lastReordersTime + duration) {
            reordersCondition = ReOrdersCondition.Period;
        } else {
            (uint256 _twap, bool _isValid) = mamm.getTiUSDPrice();
            require(_isValid, "ReOrdersController: Oracle Not Valid");

            int256 twap = _twap.toInt256();
            if (twap - PEG_PRICE > priceDelta || twap - PEG_PRICE < -priceDelta) {
                reordersCondition = ReOrdersCondition.PriceSpread;
            } else {
                revert("ReOrdersController: Do not meet any condition");
            }
        }

        uint256 pavAmount = _reorders();
        emit ReOrders(reordersCondition, pavAmount, lastReordersTime);
    }

    function _reorders() internal returns(uint) {
        // First complete the collection of swap fee, because ReOrders will change K in an unconventional way.
        mamm.mintFee();

        (uint256 _fund0, uint256 _fund1,)= mamm.getDepth();
        int256 _fund0Conv = _fund0.toInt256();
        int256 _fund1Conv = _fund1.toInt256();
        int256 _lastFund0 = lastFund0;
        int256 _lastFund1 = lastFund1;
        uint256 pavAmount;

        // scope for _fund{A,B} and _lastFund{A,B}, avoids stack too deep errors.
        {
            // Calculate the current round of PAV and the amount of TiUSD that requires mint or burn, 
            // The calculation method is detailed in the white paper:
            //      * ΔPAV_{n} = (X_{n}} - X_{n-1}) - (Y_{n-1} - Y_{n}) * PegPrice_{n}

            // _fundA is the remaining TiUSD in MAMM, _fundB is the remaining USDC in MAMM.

            int256 _fundA = _fund0Conv;
            int256 _fundB = _fund1Conv * PRECISION_CONV;
            int256 _lastFundA = _lastFund0;
            int256 _lastFundB = _lastFund1 * PRECISION_CONV;

            int256 _pavAmount = ((_fundB - _lastFundB) - (_lastFundA - _fundA) * PEG_PRICE / PRICE_PRECISION) / PRECISION_CONV;
            pavAmount = _pavAmount.toUint256();
        }
        
        // Calculate and execute PAV allocation
        if (pavAmount > 0) {
            uint256 newMMFRewards = pavAmount * mmfRewardsAllocation / 1e18;
            uint256 _newMMFRewards0 = newMMFRewards * uint256(PRECISION_CONV);
            uint256 _newMMFRewards1 = newMMFRewards;
            uint256 _newRainyDayFunds = pavAmount * rainyDayFundAllocation / 1e18;
            // Avoid rounding error
            uint256 _newProtocolFees = pavAmount - newMMFRewards - _newRainyDayFunds;

            mamm.pavAllocation(
                _newMMFRewards0,
                _newMMFRewards1, 
                _newRainyDayFunds, 
                _newProtocolFees
            );

            uint256 _balance0 = baseToken.balanceOf(address(mamm));
            uint256 _balance1 = tiusdToken.balanceOf(address(mamm));
            (uint256 _changeAmount, bool isPositive) = _balance0 * uint256(PRECISION_CONV) > _balance1 ? 
                (_balance0 * uint256(PRECISION_CONV) - _balance1, true) : (_balance1 - _balance0 *  uint256(PRECISION_CONV), false);
            tiusdToken.reorders(address(mamm), isPositive, _changeAmount);
        }
        
        mamm.sync();
        (uint256 _newfund0, uint256 _newfund1,)= mamm.getDepth();
        lastFund0 = _newfund0.toInt256();
        lastFund1 = _newfund1.toInt256();
        lastReordersTime = block.timestamp;
        return pavAmount;
    }
}