// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}



interface IDAO {
    function updateTeamBalance(uint256 amount) external;
    function updateMarketingBalance(uint256 amount) external;
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract IERC20Extended is IERC20 {
    function decimals() external view virtual returns (uint8);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

////////////////////////////////
////////// Dividend ////////////
////////////////////////////////

/*
@title Dividend-Paying Token Interface
@author Roger Wu (https://github.com/roger-wu)
@dev An interface for a dividend-paying token contract.
*/
interface IDividendPayingToken {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

/*
@title Dividend-Paying Token Optional Interface
@author Roger Wu (https://github.com/roger-wu)
@dev OPTIONAL functions for a dividend-paying token contract.
*/
interface IDividendPayingTokenOptional {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}



library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath8 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint8 a, uint8 b) internal pure returns (bool, uint8) {
        uint8 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint8 a, uint8 b) internal pure returns (bool, uint8) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint8 a, uint8 b) internal pure returns (bool, uint8) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint8 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint8 a, uint8 b) internal pure returns (bool, uint8) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint8 a, uint8 b) internal pure returns (bool, uint8) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) return 0;
        uint8 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b > 0, errorMessage);
        return a % b;
    }
}



/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}



/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/*
@title Dividend-Paying Token
@author Roger Wu (https://github.com/roger-wu)
@dev A mintable ERC20 token that allows anyone to pay and distribute ether
to token holders as dividends and allows token holders to withdraw their dividends.
Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
*/
contract DividendPayingToken is ERC20, Ownable, IDividendPayingToken, IDividendPayingTokenOptional {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;
    
    address public dividendToken;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) public magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol, address _token) ERC20(_name, _symbol) {
        dividendToken = _token;
    }

    receive() external payable {
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public onlyOwner override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add( (msg.value).mul(magnitude) / totalSupply() );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }
  

    function distributeDividends(uint256 amount) public onlyOwner {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add( (amount).mul(magnitude) / totalSupply() );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed.add(amount);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }
    
    function setDividendTokenAddress(address newToken) external virtual onlyOwner {
        require(newToken != address(0), "Zero address yort");
        dividendToken = newToken;
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }


    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }


    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance)
        {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        }
        else if(newBalance < currentBalance)
        {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract DogeGaySonFlat is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMath8 for uint8;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public cakeDividendToken;

    address public gogeDao;
    address public immutable GogeV1;

    address constant public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address[] public excludedFromCirculatingSupply;

    bool private swapping;
    bool public tradingIsEnabled;
    bool public marketingEnabled;
    bool public buyBackEnabled;
    bool public devEnabled;
    bool public cakeDividendEnabled;
    bool public teamEnabled;

    CakeDividendTracker public cakeDividendTracker;

    address public teamWallet;
    address public marketingWallet;
    address public devWallet;
    
    uint256 public swapTokensAtAmount;

    uint8 public cakeDividendRewardsFee;
    uint8 public previousCakeDividendRewardsFee;

    uint8 public marketingFee;
    uint8 public previousMarketingFee;

    uint8 public buyBackFee;
    uint8 public previousBuyBackFee;

    uint8 public teamFee;
    uint8 public previousTeamFee;

    uint8 public totalFees;

    uint256 public gasForProcessing = 600000;
    uint256 public migrationCounter;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public lastReceived;
    mapping(uint8 => uint256) public royaltiesSent;

    uint256 public _firstBlock;

    event CakeDividendTrackerUpdated(address indexed newAddress, address indexed oldAddress);
    
    event MarketingEnabledUpdated(bool enabled);
    event BuyBackEnabledUpdated(bool enabled);
    event TeamEnabledUpdated(bool enabled);
    event CakeDividendEnabledUpdated(bool enabled);

    event ProcessedCakeDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    event FeesUpdated(uint8 totalFee, uint8 rewardFee, uint8 marketingFee, uint8 buybackFee, uint8 teamFee);
   
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event TeamWalletUpdated(address indexed newTeamWallet, address indexed oldTeamWallet);

    event RoyaltiesTransferred(address indexed wallet, uint256 amountEth);

    event SendDividends(uint256 amount);

    event BuybackInitiated(uint256 amountIn, address[] path);

    event Erc20TokenWithdrawn(address token, uint256 amount);

    event AddressExcludedFromCirculatingSupply(address account, bool excluded);

    event Migrated(address indexed account, uint256 amount);
    
    event TradingEnabled(uint256 timestamp);
    
    constructor() ERC20("DogeGaySon", "GOGE") {

        cakeDividendTracker = new CakeDividendTracker();

        marketingWallet = 0xFecf1D51E984856F11B7D0872D40fC2F05377738;
        teamWallet = 0xC1Aa023A8fA820F4ed077f4dF4eBeD0a3351a324;
        devWallet = 0xa13bBda8bE05462232D7Fc4B0aF8f9B57fFf5D02;
        cakeDividendToken = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
        
        GogeV1 = 0xa30D02C5CdB6a76e47EA0D65f369FD39618541Fe;
        
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        
        // exclude from paying dividends to the team wallets and dead addresses
        cakeDividendTracker.excludeFromDividends(address(cakeDividendTracker));
        cakeDividendTracker.excludeFromDividends(address(this));
        cakeDividendTracker.excludeFromDividends(address(uniswapV2Router));
        cakeDividendTracker.excludeFromDividends(DEAD_ADDRESS);

        // exclude from paying fees or having max transaction amount
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[DEAD_ADDRESS] = true;
        
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {}

    function setGogeDao(address _gogeDao) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setgogeDao() msg.sender is not owner or gogeDao");
        require(gogeDao != _gogeDao, "GogeToken.sol::setgogeDao() address is already set");

        gogeDao = _gogeDao;

        isExcludedFromFees[gogeDao] = true;
        cakeDividendTracker.excludeFromDividends(gogeDao);
    }

    function addPartnerOrExchange(address _partnerOrExchangeAddress) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::addPartnerOrExchange() msg.sender is not owner or gogeDao");
        cakeDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        isExcludedFromFees[_partnerOrExchangeAddress] = true;
    }
    
    function updateCakeDividendToken(address _newContract) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateCakeDividendToken() msg.sender is not owner or gogeDao");
        require(_newContract != address(0), "GogeToken.sol::updateCakeDividendToken() Zero address yort");

        cakeDividendToken = _newContract;
        cakeDividendTracker.setDividendTokenAddress(_newContract);
    }
    
    function updateTeamWallet(address _newWallet) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateTeamWallet() msg.sender is not owner or gogeDao");
        require(_newWallet != teamWallet, "GogeToken.sol::updateTeamWallet() address is already set");

        isExcludedFromFees[_newWallet] = true;
        teamWallet = _newWallet;

        emit TeamWalletUpdated(teamWallet, _newWallet);
    }
    
    function updateMarketingWallet(address _newWallet) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateMarketingWallet() msg.sender is not owner or gogeDao");
        require(_newWallet != marketingWallet, "GogeToken.sol::updateMarketingWallet() address is already set");

        isExcludedFromFees[_newWallet] = true;
        marketingWallet = _newWallet;

        emit MarketingWalletUpdated(marketingWallet, _newWallet);
    }
    
    function updateSwapTokensAtAmount(uint256 _swapAmount) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateSwapTokensAtAmount() msg.sender is not owner or gogeDao");
        swapTokensAtAmount = _swapAmount * (10**18);
    }
    
    function enableTrading() external onlyOwner {
        require(!tradingIsEnabled, "GogeToken.sol::enableTrading() trading is already enabled");

        cakeDividendRewardsFee = 10;
        marketingFee = 2;
        buyBackFee = 2;
        teamFee = 2;
        totalFees = 16;
        marketingEnabled = true;
        buyBackEnabled = true;
        cakeDividendEnabled = true;
        teamEnabled = true;
        swapTokensAtAmount = 20_000_000 * (10**18);
        tradingIsEnabled = true;
        _firstBlock = block.timestamp;

        emit TradingEnabled(_firstBlock);
    }
    
    function setBuyBackEnabled(bool _enabled) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setBuyBackEnabled() not authorized");
        require(buyBackEnabled != _enabled, "GogeToken.sol::setBuyBackEnabled() can't set flag to same status");

        if (_enabled) {
            buyBackFee = previousBuyBackFee;
            buyBackEnabled = _enabled;
        } else {
            previousBuyBackFee = buyBackFee;
            buyBackFee = 0;
            buyBackEnabled = _enabled;
        }
        totalFees = buyBackFee.add(marketingFee).add(cakeDividendRewardsFee).add(teamFee);
        
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setCakeDividendEnabled(bool _enabled) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setCakeDividendEnabled() not authorized");
        require(cakeDividendEnabled != _enabled, "GogeToken.sol::setCakeDividendEnabled() can't set flag to same status");

        if (_enabled) {
            cakeDividendRewardsFee = previousCakeDividendRewardsFee;
            cakeDividendEnabled = _enabled;
        } else {
            previousCakeDividendRewardsFee = cakeDividendRewardsFee;
            cakeDividendRewardsFee = 0;
            cakeDividendEnabled = _enabled;
        }
        totalFees = cakeDividendRewardsFee.add(marketingFee).add(buyBackFee).add(teamFee);

        emit CakeDividendEnabledUpdated(_enabled);
    }
    
    function setMarketingEnabled(bool _enabled) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setMarketingEnabled() not authorized");
        require(marketingEnabled != _enabled, "GogeToken.sol::setMarketingEnabled() can't set flag to same status");

        if (_enabled) {
            marketingFee = previousMarketingFee;
            marketingEnabled = _enabled;
        } else {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        }
        totalFees = marketingFee.add(cakeDividendRewardsFee).add(buyBackFee).add(teamFee);

        emit MarketingEnabledUpdated(_enabled);
    }

    function setTeamEnabled(bool _enabled) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setTeamEnabled() not authorized");
        require(teamEnabled != _enabled, "GogeToken.sol::setTeamEnabled() can't set flag to same status");

        if (_enabled) {
            teamFee = previousTeamFee;
            teamEnabled = _enabled;
        } else {
            previousTeamFee = teamFee;
            teamFee = 0;
            teamEnabled = _enabled;
        }
        totalFees = teamFee.add(cakeDividendRewardsFee).add(buyBackFee).add(marketingFee);

        emit TeamEnabledUpdated(_enabled);
    }

    function updateCakeDividendTracker(address newAddress) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateCakeDividendTracker() msg.sender must be owner or gogeDao");
        require(newAddress != address(cakeDividendTracker), "GogeToken.sol::updateCakeDividendTracker() The dividend tracker already has that address");

        CakeDividendTracker newCakeDividendTracker = CakeDividendTracker(payable(newAddress));

        require(newCakeDividendTracker.owner() == address(this), "GogeToken.sol::updateCakeDividendTracker() the new dividend tracker must be owned by this token contract");

        newCakeDividendTracker.excludeFromDividends(address(newCakeDividendTracker));
        newCakeDividendTracker.excludeFromDividends(address(this));
        newCakeDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newCakeDividendTracker.excludeFromDividends(address(DEAD_ADDRESS));
        newCakeDividendTracker.excludeFromDividends(address(0));

        cakeDividendTracker = newCakeDividendTracker;

        emit CakeDividendTrackerUpdated(newAddress, address(cakeDividendTracker));
    }
    
    function updateFees(uint8 _rewardFee, uint8 _marketingFee, uint8 _buybackFee, uint8 _teamFee) external {
        totalFees = _rewardFee + _marketingFee + _buybackFee + _teamFee;

        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateFees() not authorized");
        require(totalFees <= 40, "GogeToken.sol::updateFees() sum of fees cannot exceed 40%");
        
        cakeDividendRewardsFee = _rewardFee;
        marketingFee = _marketingFee;
        buyBackFee = _buybackFee;
        teamFee = _teamFee;

        emit FeesUpdated(totalFees, _rewardFee, _marketingFee, _buybackFee, _teamFee);
    }
    
    function updateUniswapV2Router(address newAddress) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::UpdatedUniswapV2Router() not authorized");
        require(newAddress != address(uniswapV2Router), "GogeToken.sol::UpdatedUniswapV2Router() the router already has that address");

        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::excludeFromFees() not authorized");

        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::excludeFromDividend() not authorized");
        cakeDividendTracker.excludeFromDividends(address(account)); 
    }

    function isExcludedFromCirculatingSupply(address _address) public view returns(bool, uint8) {
        for (uint8 i = 0; i < excludedFromCirculatingSupply.length; i++){
            if (_address == excludedFromCirculatingSupply[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function excludeFromCirculatingSupply(address account, bool excluded) public {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::excludeFromCirculatingSupply() not authorized");

        (bool _isExcluded, uint8 i) = isExcludedFromCirculatingSupply(account);
        require(_isExcluded != excluded, "GogeToken.sol::excludeFromCirculatingSupply() account already set to that boolean value");

        if(excluded) {
            if (!cakeDividendTracker.excludedFromDividends(account)) {
                cakeDividendTracker.excludeFromDividends(account);
            }
            if(!_isExcluded) excludedFromCirculatingSupply.push(account);        
        } else {
            if(_isExcluded){
                excludedFromCirculatingSupply[i] = excludedFromCirculatingSupply[excludedFromCirculatingSupply.length - 1];
                excludedFromCirculatingSupply.pop();
            } 
        }

        emit AddressExcludedFromCirculatingSupply(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::setAutomatedMarketMakerPair() not authorized");
        require(pair != uniswapV2Pair, "GogeToken.sol::setAutomatedMarketMakerPair() the PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) internal {
        require(automatedMarketMakerPairs[pair] != value, "GogeToken.sol::_setAutomatedMarketMakerPair() Automated market maker pair is already set to that value");

        automatedMarketMakerPairs[pair] = value;
        excludeFromCirculatingSupply(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::updateMinimumBalanceForDividends() not authorized");
        cakeDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function claim() external {
        cakeDividendTracker.processAccount(payable(msg.sender), false);     
    }

    function buyBackAndBurn(uint256 amount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            DEAD_ADDRESS, // Burn address
            block.timestamp.add(300)
        );

        emit BuybackInitiated(amount, path);
    }

    function migrate() external {
        uint256 amount = IERC20(GogeV1).balanceOf(_msgSender());

        require(IERC20(GogeV1).transferFrom(_msgSender(), address(this), amount), "GogeToken.sol::migrate() transfer from msg.sender to address(this) failed");
        require(IERC20(GogeV1).balanceOf(_msgSender()) == 0, "GogeToken.sol::migrate() msg.sender post balance > 0");
        
        _mint(_msgSender(), amount);
        require(balanceOf(_msgSender()) == amount, "GogeToken.sol::migrate() msg.sender post v2 balance == 0");

        captureLiquidity();
        migrationCounter++;
        
        emit Migrated(_msgSender(), amount);
    }

    function captureLiquidity() internal {
        address[] memory path = new address[](2);
        path[0] = GogeV1;
        path[1] = uniswapV2Router.WETH();

        uint256 tokenAmount = IERC20(GogeV1).balanceOf(address(this));
        //_approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(GogeV1).approve(address(uniswapV2Router), tokenAmount);
        uint256 contractBnbBalance = address(this).balance;

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 bnbAmount = (address(this).balance).sub(contractBnbBalance);

        // mint to liquidity
        uint256 contractTokenBalance = balanceOf(address(this));
        _mint(address(this), tokenAmount);

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}( // NOTE: if does not maintain ratio, will refund
            address(this),
            tokenAmount,
            0,         // amountTokenMin
            bnbAmount, // amountETHMin
            owner(),   // receiver of LP token
            block.timestamp + 100
        );

        // burn surplus of minted tokens
        if (balanceOf(address(this)) > contractTokenBalance) {
            _burn(address(this), balanceOf(address(this)).sub(contractTokenBalance));
        }
    }

    function getCirculatingMinusReserve() external view returns(uint256 circulating) {
        circulating = totalSupply() - (balanceOf(DEAD_ADDRESS) + balanceOf(address(0)));
        for (uint8 i = 0; i < excludedFromCirculatingSupply.length; i++) {
            circulating = circulating - balanceOf(excludedFromCirculatingSupply[i]);
        }
    }

    function getLastReceived(address voter) external view returns(uint256) {
        return lastReceived[voter];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount

    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "GogeToken.sol::_transfer() trading is not enabled or wallet is not whitelisted");
        
        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];
        
        if ( // NON whitelisted buy
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            // if receiver or sender is blacklisted, revert
            require(!isBlacklisted[from], "GogeToken.sol::_transfer() sender is blacklisted");
            require(!isBlacklisted[to],   "GogeToken.sol::_transfer() receiver is blacklisted");
            lastReceived[to] = block.timestamp;
        }
        
        else if ( // NON whitelisted sell
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            // if receiver or sender is blacklisted, revert
            require(!isBlacklisted[from], "GogeToken.sol::_transfer() sender is blacklisted");
            require(!isBlacklisted[to],   "GogeToken.sol::_transfer() receiver is blacklisted");
            
            // take contract balance of royalty tokens
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                swapTokensForBNB(contractTokenBalance);
                
                uint256 contractBnbBalance = address(this).balance;
                uint8   feesTaken = 0;
                
                if (marketingEnabled) {
                    uint256 marketingPortion = contractBnbBalance.mul(marketingFee).div(totalFees);
                    contractBnbBalance = contractBnbBalance - marketingPortion;
                    feesTaken = feesTaken + marketingFee;
                    royaltiesSent[1] += marketingPortion;

                    transferToWallet(payable(marketingWallet), marketingPortion);
                    if (marketingWallet == gogeDao) IDAO(gogeDao).updateMarketingBalance(marketingPortion);

                    if(block.timestamp < _firstBlock + (60 days)) { // dev fee only lasts for 60 days post launch.
                        uint256 devPortion = contractBnbBalance.mul(2).div(totalFees - feesTaken);
                        contractBnbBalance = contractBnbBalance - devPortion;
                        feesTaken = feesTaken + 2;
                    
                        royaltiesSent[2] += devPortion;
                        transferToWallet(payable(devWallet), devPortion);
                    }
                }

                if (teamEnabled) {
                    uint256 teamPortion = contractBnbBalance.mul(teamFee).div(totalFees - feesTaken);
                    contractBnbBalance = contractBnbBalance - teamPortion;
                    feesTaken = feesTaken + teamFee;
                    royaltiesSent[3] += teamPortion;

                    transferToWallet(payable(teamWallet), teamPortion);
                    if (teamWallet == gogeDao) IDAO(gogeDao).updateTeamBalance(teamPortion);
                }
                
                if (buyBackEnabled) {
                    uint256 buyBackPortion = contractBnbBalance.mul(buyBackFee).div(totalFees - feesTaken);
                    contractBnbBalance = contractBnbBalance - buyBackPortion;
                    feesTaken = feesTaken + buyBackFee;
                    royaltiesSent[4] += buyBackPortion;

                    if (buyBackPortion > uint256(1 * 10**17)) { // if amount > .1 bnb
                        buyBackAndBurn(buyBackPortion);
                    }
                }
                
                if (cakeDividendEnabled) {
                    royaltiesSent[5] += contractBnbBalance;
                    swapAndSendCakeDividends(contractBnbBalance);
                }
    
                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping && !excludedAccount;

        if(takeFee) {
            require(!isBlacklisted[from], "GogeToken.sol::_transfer() sender is blacklisted");
            require(!isBlacklisted[to],   "GogeToken.sol::_transfer() receiver is blacklisted");

            uint256 fees;

            fees = amount.mul(totalFees).div(100);
            lastReceived[to] = block.timestamp;
        
            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        if(from != gogeDao && to != gogeDao) {
            try cakeDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
            
            try cakeDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
            
            if(!swapping) {
                uint256 gas = gasForProcessing;

                try cakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                    emit ProcessedCakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                }
                catch {

                }
            }
        }
    }

    function modifyBlacklist(address account, bool blacklisted) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "GogeToken.sol::modifyBlacklist() not authorized");
        isBlacklisted[account] = blacklisted;
    }

    function swapTokensForBNB(uint256 tokenAmount) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        // generate the uniswap pair path of weth -> cake
        address[] memory path = new address[](2);//3);
        //path[0] = address(this);
        path[0] = uniswapV2Router.WETH();
        path[1] = _dividendAddress;

        //_approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _tokenAmount}(
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }

    function swapAndSendCakeDividends(uint256 tokens) internal {
        swapTokensForDividendToken(tokens, address(this), cakeDividendToken);
        uint256 cakeDividends = IERC20(cakeDividendToken).balanceOf(address(this));

        assert(IERC20(cakeDividendToken).transfer(address(cakeDividendTracker), cakeDividends));

        cakeDividendTracker.distributeDividends(cakeDividends);
        emit SendDividends(cakeDividends);
    }
    
    function transferToWallet(address payable recipient, uint256 amount) internal {
        recipient.transfer(amount);
        emit RoyaltiesTransferred(recipient, amount);
    }
    
    function _transferOwnership(address newOwner) external {
        require(_msgSender() == gogeDao || _msgSender() == owner(), "Not authorized");
        require(newOwner != address(0));

        super.transferOwnership(newOwner);
        
        isExcludedFromFees[newOwner] = true;
        cakeDividendTracker.excludeFromDividends(newOwner);
    }

    /// @notice Withdraw a gogeToken from the treasury.
    /// @dev    Only callable by owner.
    /// @param  _token The token to withdraw from the treasury.
    function safeWithdraw(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "GogeToken.sol::safeWithdraw() Insufficient token balance");
        require(_token != address(this), "GogeToken.sol::safeWithdraw() cannot remove $GOGE from this contract");

        assert(IERC20(_token).transfer(msg.sender, amount));

        emit Erc20TokenWithdrawn(_token, amount);
    }

}

contract CakeDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("DogeGaySon_Ethereum_Dividend_Tracker", "DogeGaySon_Ethereum_Dividend_Tracker", 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82) {
    	claimWait = 3600; // 1 hour
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        revert("DogeGaySon_Ethereum_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        revert("DogeGaySon_Ethereum_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main DogeGaySon contract.");
    }
    
    function setDividendTokenAddress(address newToken) external override onlyOwner {
        require(newToken != address(0), "Zero address yort");
        dividendToken = newToken;
    }
    
    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DogeGaySon_Ethereum_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DogeGaySon_Ethereum_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }


    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) public view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }

    function getMapValue(address key) external view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function getMapLength() external view returns (uint) {
        return tokenHoldersMap.keys.length;
    }
}