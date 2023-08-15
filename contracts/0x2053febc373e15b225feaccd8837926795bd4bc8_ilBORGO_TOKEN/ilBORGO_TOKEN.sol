/**
 *Submitted for verification at Etherscan.io on 2023-07-26
*/

/* SPDX-License-Identifier: MIT

All rights reserved by Slenos Srl Startup Innovativa
Notarized White Paper describing the decentralized system for tokenization of the luxury widespread
Hotel in Borgo di Sempronio - Tuscany (Italy)
https://app.dedit.io/verification/11da55d94b222ec07e5132c8fdc050582ebc745d60eec33b615823d7cf4ff3d9

Project site: https://BorgoToken.com
Hotel site: https://BorgoDiSempronio.com/
Team site: https://www.slenoscapital.com/
 
ilBORGO tokenPriceUSDC
Super Private sale: 0.80 USDC - LOCKUP 6 MONTHS
Private sale: 1.0 USDC - LOCKUP 6 MONTHS
Pre sale: 1.2 USDC - LOCKUP 48 hours
Public Sale 1.3 USDC

ilBorgo token will entitle the holder to convert TOKENS into an equity financial instrument (SFP)*
that gives the right to participation in the profits of management and any capital gain on the future sale of real estate.
*KYC will be mandatory when converting tokens in SFP

*/

pragma solidity ^0.8.7;
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function max(uint256 a, uint256 b) internal pure returns (uint256) {        
        return a >= b ? a : b; 
    }
}

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

/*
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
/* UniSwap Interface */
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
/*
    UNUSED FUNCTIONS TO SAVE GAS 

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
   

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts); */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    /*
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    /
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);*/
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  /*  
    UNUSED FUNCTIONS TO SAVE GAS 
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
    */
}

interface IUniswapV2Factory {
/*    

    UNUSED FUNCTIONS TO SAVE GAS 

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
*/

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

/**
 * @dev Implementation of the {IERC20} interface.
 
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance:");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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


/// @title Reward-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as rewards and allows token holders to withdraw their rewards.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract RewardPayingToken  {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  //  using IterableMapping for IterableMapping.Map;

  // With `magnitude`, we can properly distribute rewards even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 public magnifiedDividendPerShare;

  // About rewardCorrection:
  // If the token balance of a `_user` is never changed, the reward of `_user` can be computed with:
  //   `rewardOf(_user) = rewardPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `rewardOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `rewardOf(_user)` unchanged, we add a correction term:
  //   `rewardOf(_user) = rewardPerShare * balanceOf(_user) + rewardCorrectionOf(_user)`,
  //   where `rewardCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `rewardCorrectionOf(_user) = rewardPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `rewardOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) public magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnRewards;
  mapping(address => uint256) internal withdrawnNum;

  uint256 public totalRewardsDistributed;

  uint256 public totalRewardsCorrection;

  uint256 public totalRewardsCreated;

  mapping(address => uint256) public paidRewards;

  mapping(address => uint256) internal withdrawnDividends; 
  

  
    uint256 public totalDividendsDistributed;

    uint256 public totalDvidendsCreated;

    mapping (address => bool) public excludedFromRewards;

    mapping (address => uint256) public lastClaimTimes;
    mapping (address => uint256) public numClaimsAccount;

    uint256 public rewardInterval = 7 days; 
    uint256 public minimumTokenBalanceForRewards =  10 * (10**18);//10 ;
    uint256 public rewardRate = 1000000000;// with 12 decimals divider : 1000000000 -> 0,1%

    IERC20 public MYTOKEN = IERC20(address(this));
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    bool public dividendIsOpen = false;//will be activated with the first distribution
    
  /// @notice Distributes ether to token holders as rewards.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `RewardsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed USDC in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  

    function _distributeDividends(uint256 _dividends) internal {// FROM VALUE TO TOKENS
        dividendIsOpen = true;
        USDC.transferFrom(msg.sender, address(this), _dividends);
        uint256 supply = MYTOKEN.totalSupply().sub(totalRewardsCorrection);

        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (_dividends).mul(magnitude) / supply //ERC20(address(this)).balanceOf(address(this))
        );
        totalDvidendsCreated = totalDvidendsCreated.add(_dividends);
    }
    
    
    
    function _setDevidendStatus(bool _isOn) internal returns (bool )  {
        dividendIsOpen = _isOn;
        return _isOn;
    }


  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawRewardOfUser(address  user) internal returns (uint256) {//RIO EX payable
    uint256 _withdrawableReward = withdrawableRewardOf(user);
    if (_withdrawableReward > 0) {
      withdrawnRewards[user] = withdrawnRewards[user].add(_withdrawableReward);
    
         withdrawnNum[user]++;

        MYTOKEN.transfer(user, _withdrawableReward);    

        totalRewardsDistributed = totalRewardsDistributed.add(_withdrawableReward);
        
      return _withdrawableReward;
    }

    return 0;
  }
  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `RewardWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendsOfUser(address  user) internal returns (uint256) {//RIO EX payable
    uint256 _withdrawableDividend = dividendsOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
    
      withdrawnNum[user]++;

        USDC.transfer(user, _withdrawableDividend);    

        totalDividendsDistributed = totalDividendsDistributed.add(_withdrawableDividend);
       
      return _withdrawableDividend;
    }

    return 0;
  }
  /// @notice View the amount of dividends in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividends in wei that `_owner` can withdraw.
function accumulativeDividendOf(address _owner) public view returns(uint256) {
      
    uint256 balance = MYTOKEN.balanceOf(_owner).sub(withdrawnRewards[_owner]).add(paidRewards[_owner]);

    return magnifiedDividendPerShare.mul(balance).toInt256()
      .add(magnifiedDividendCorrections[_owner]).toUint256() / magnitude;
  }

/// @notice View the amount of dividends in wei that an address can withdraw.
function dividendsOf(address _owner) public view  returns(uint256) {
    if(excludedFromRewards[_owner]) {
        return 0;
    }

    (bool check, uint256 rew) = SafeMath.trySub(accumulativeDividendOf(_owner),withdrawnDividends[_owner]);
    if(check){return rew;}else{return 0;}

}

  /// @return The amount of reward in wei that `_owner` can withdraw from the beginning or last time claiming
  function rewardOfTime(address _owner) public view  returns(uint256) {
    uint256 balance = MYTOKEN.balanceOf(_owner);

   uint256 rewards;
        
        (bool check, uint256 period) = SafeMath.trySub(block.timestamp,lastClaimTimes[_owner]);

        if(check && period.div(rewardInterval) > 0){ //
        
            (bool check1, uint256 rew) = SafeMath.tryDiv((balance * rewardRate),(10 ** 12));
                if(check1){
                uint256 dias = period.div(rewardInterval);
                rewards = rew.mul(dias);

             }
        }
        return rewards;
  }

    /* calculate reward for time left from purchases or last claim */
    function withdrawableRewardOf(address _owner) public view  returns(uint256) {
        return rewardOfTime(_owner); 
    }

  /// @return The amount of rewards in wei that `_owner` withdrawn from the beginning
    function withdrawnRewardOf(address _owner) public view  returns(uint256) {
        return withdrawnRewards[_owner];
    }
  /// @return The amount of dividends in wei that `_owner` withdrawn from the beginning
    function withdrawnDividendsOf(address _owner) public view  returns(uint256) {
        return withdrawnDividends[_owner];
    }
//last claim date by the holder
    function getLastClaimRewardTime(address _holder) public view returns (uint256) {
       return lastClaimTimes[_holder];
    }
//how many times interval reward is occorred
//for an intervalPeriod setted on 1 day, on the year end the amount will be 365
    function getNumClaimDays(address _holder) public view returns (uint256) {
       return numClaimsAccount[_holder];
    }
    function canClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= rewardInterval;
    }

// PROCESS REWARD DISTRIBUTION
    function processAccount(address account, uint256 lastDistributionDay) internal  returns (bool) {
        
        uint256 iniTime = lastClaimTimes[account];
        if(canClaim(iniTime)) { 
        uint256 amount = _withdrawRewardOfUser(account);

    	if(amount > 0) {
            uint256 dias = (block.timestamp.sub(iniTime)).div(rewardInterval);
            numClaimsAccount[account] = numClaimsAccount[account].add(dias);

    		lastClaimTimes[account] = lastDistributionDay;

    		return true;
    	    }
      }

   return false;
    }
   
    function withdrawDividendsOfUser(address account) public {
           if(dividendIsOpen)
            _withdrawDividendsOfUser(account);
    }
     
}


contract ilBORGO_TOKEN is ERC20, RewardPayingToken{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
        
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
  
    uint256 public MAX_SUPPLY = 5_480_000 * (10 ** uint256(18));
/* 
        ilBORGO tokenPriceUSDC
        Super Private sale: 0.80 USDC - LOCKUP 6 MONTHS
        Private sale: 1.0 USDC - LOCKUP 6 MONTHS
        Pre sale: 1.2 USDC -LOCKUP 48 hours
*/

    uint256 public tokenPriceUSDC = 80; // = 0.80 USDC  divider 100
    
    uint256 public maxSellTransactionAmount = 500_000 * (10**18);//ANTI-WHALE

    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //->mainnet eth 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D BSC 0x10ED43C718714eb63d5aA57B78B54704E256024E

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;// main ETH 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 BSC 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c

    address public uniswapV2Pair;

    bool public mintingIsLive = true;
     
    bool public inRewardsPaused = true;

    bool public sendAndLiquifyEnabled = false;

    address public deadWallet = address(0x000000000000000000000000000000000000dEaD);

    uint256 public lastSentToContract; //last reward distribution date
    
    mapping(address => bool) private _isExcludedFromMaxTx;

    //Admin operation record
    uint256 public withdrawns;
    uint256 public deposits;

    address public owner;
    mapping (address => bool) public allowedWallet; // wallet allowed to call only mint operations in private sale

    /* lockup private sale Token 
    lockup period is: 6 MONTHS for private sale and 48 HOURS for presale
    */
    bool public isLockupOn = true;
    uint256 lockupTime = 180 days; 
    mapping(address => uint256) internal lockedUntil;

    bool public tradeIsOpen = false;

    //presale contract address will added to whitelist
    mapping(address => bool) internal _whiteList;

    /* The function allow Wallet to Mint Tokens payied by bank transfer and credit card */
    function addAllowedWallet(address _wallet, bool isAllowed) public   {
        allowedWallet[_wallet] = isAllowed;
    }

    //full transfership allowance for public sale
    function openTrade(bool _isOpen) external onlyOwner {
        tradeIsOpen = _isOpen;
    }
    
    function setLockupStatus(bool _isOn) external onlyOwner {
        isLockupOn = _isOn;
    }

    //change the lockup time for the presale 
    function setLockupTime(uint256 _seconds) external onlyOwner {
        lockupTime = _seconds;
    }
    //include expecptions to openTrade
    function includeToWhiteList(address[] memory _users) external onlyOwner {
        for(uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

/* 
        ilBORGO tokenPriceUSDC
        Super Private sale: 0.80 USDC - LOCKUP 6 MONTHS
        Private sale: 1.0 USDC - LOCKUP 6 MONTHS
        Pre sale: 1.2 USDC -LOCKUP 48 hours
*/

    function setTokenPriceUSDC(uint256 _priceX100) external onlyOwner {
        tokenPriceUSDC = _priceX100; // Eg.: 100 = 1 USDC => 1 TOKEN
    }


    constructor() ERC20("BORGO TOKEN","ilBORGO") {
        
        owner = msg.sender;
        allowedWallet[owner] = true;

        _whiteList[owner] = true;
        _whiteList[address(this)] = true;
        
        excludeFromRewards(owner,true);//owner doesn't receive token rewards
        excludeFromRewards(address(this),true);
        excludeFromRewards(0x000000000000000000000000000000000000dEaD,true);

        // exclude from max tx
        _isExcludedFromMaxTx[owner] = true;
        _isExcludedFromMaxTx[address(this)] = true;

    }

    modifier onlyOwner() {
        require(owner == msg.sender , "caller is not the owner");
        _;
    }

// Create a UniSwap pair for this new token 
    function createLiquidityPool() public onlyOwner  {
        
         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        excludeFromRewards(address(uniswapV2Router),true);

    }

    function setMintingIsLive(bool _isOn) public onlyOwner returns (bool )  {
        mintingIsLive = _isOn;
        return _isOn;
    }

    function setinRewardsPaused(bool _bool) public onlyOwner {
        inRewardsPaused = _bool;
    }
    
    //admin can set the beginning of token rewards
    function setLastSentToContract(uint256 _date) public onlyOwner {
        lastSentToContract = _date;
    }

    function excludeFromRewards(address account, bool value) public onlyOwner {
    	excludedFromRewards[account] = value;
    }
        
    function isExcludedFromRewards(address account) public view returns(bool) {
        return excludedFromRewards[account];
    }

    /* exclude from anti whale */
    function excludeFromMaxTx(address _address, bool value) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = value;
    }

    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function updateUniswapV2Router(address newRouter) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newRouter);
    }

// external call to claim token rewards
    function claimRewards() external {
        if(
            !inRewardsPaused 
        ) {
        sendAndLiquify();
		processAccount(msg.sender, lastSentToContract);
        }
    }
   
 // external call to withdraw USDC dividends
    function claimDividends() external {
		withdrawDividendsOfUser(msg.sender);     
    }


//Enable/disable rewards distribution
    function setSendAndLiquifyEnabled(bool _enabled) public onlyOwner {
        sendAndLiquifyEnabled = _enabled;
        lastSentToContract = block.timestamp;
    }

//possible Anti-wales  option
    function setMaxSellTransactionAmount(uint256 newAmount) public onlyOwner 
    {
        maxSellTransactionAmount = newAmount;
    }    
    
/* DEFAULT FUNCTIONS */
    function _transfer(address from, address to, uint256 amount) 
//    isOpenTrade(from, to) //openTrade lock managing
     internal override 
    {
        require(!isLockupOn || lockedUntil[from] < block.timestamp, "Locked");
        require(tradeIsOpen || _whiteList[from] || _whiteList[to], "Not Open");

        if(amount == 0) {
            return;
        }

        if((!_isExcludedFromMaxTx[from]) && (!_isExcludedFromMaxTx[to]))
        {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }
       
        setBuyTime(to);  //call before transfer
        
        if(from != address(this)){

       subCorrection(from,amount);
       addCorrection(to,amount);
            if(!inRewardsPaused ) {
                sendAndLiquify();
                processAccount(from, lastSentToContract);           
            }
         }
         
        super._transfer(from, to, amount);
        
    }
    
/* 
    ONLY PURCHASED TOKENS ARE CALCULATED TO RECEIVE DIVIDENDS   
*/

    function addCorrection(address account,uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256() );
    }

    function subCorrection(address account,uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256() );
    }

//mint token for the exact amount of holders
    function sendAndLiquify() public {
        if(!sendAndLiquifyEnabled)return;
        uint256 rewards;
       // uint256 rewardInterval = rewardInterval();
        
        (bool check, uint256 period) = SafeMath.trySub(block.timestamp,lastSentToContract);

        if(check && period.div(rewardInterval) > 0){ //
        
            (bool check1, uint256 rew) = SafeMath.tryDiv((totalSupply() * rewardRate),(10 ** 12));
                if(check1){
                uint256 dias = period.div(rewardInterval);
                rewards = rew.mul(dias);
               
                if(rewards>0){
                
                totalRewardsCorrection = totalRewardsCorrection.add(rewards);

                _mint(address(this), rewards);

                lastSentToContract += dias.mul(rewardInterval);
                
                }
             }
        }

    }
function distributeDividends(uint256 _dividends) public  onlyOwner{
    _distributeDividends(_dividends);
}
function setDevidendStatus(bool _isOn) public onlyOwner  { 
   _setDevidendStatus(_isOn);
}
//SET FOR FIRST PURCHASE ONLY : to avoid misalignment we set buyTime = last distribution time but with a max of token reward interval
    function setBuyTime(address _holder) internal {
        if(balanceOf(_holder)==0){
            uint256 _time;
            //nel caso non si minti dopo il deploy
            if(totalSupply()==0)lastSentToContract = block.timestamp;

            if(block.timestamp.sub(lastSentToContract) < rewardInterval){
                _time = lastSentToContract;
            }else{
                _time = block.timestamp;
            }
            
            setBuyTime2(_holder,_time);
        }

    }

    function setBuyTime2(address _holder, uint256 _time) internal {

        lastClaimTimes[_holder] = _time;
    }
    
    function updateRewardInterval(uint256 newRewardInterval) external onlyOwner {
        require(newRewardInterval != rewardInterval, "ABC_Reward_Tracker: Cannot update RewardInterval to same value");
        rewardInterval = newRewardInterval;
    }

    function setMinimumTokenBalanceForRewards(uint256 _minimumTokenBalanceWei) public onlyOwner {
        minimumTokenBalanceForRewards = _minimumTokenBalanceWei;
    }



    /* ilBORGO TOKEN MINTING*/

     /* PAY WITH ETH */
    function buyToken () public payable returns (bool){//uint256 tokens
        require(mintingIsLive , "Minting is OFF LINE");
        uint amount = msg.value;
        require(amount > 0, "Not enough Tokens to buy");
        
        address _holder = msg.sender;
        if(!inRewardsPaused ) 
        { 
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }

        //calculate token amount for tokenPriceUSDC and add 12 decimal from USDC deposit
        uint256 tokens = swapEthToUsdcAndSendTo(amount,owner).mul(10 ** 12).mul(100).div(tokenPriceUSDC);
        
        require(totalSupply().add(tokens) <= MAX_SUPPLY,"MAX SUPPLY reached");

        setBuyTime(_holder);  //call before minting

        _mint(_holder,tokens);

        addCorrection(_holder,tokens);
        
        if(isLockupOn){
            if(lockedUntil[_holder]==0)lockedUntil[_holder] = block.timestamp + lockupTime;
        }        
        return true;
    }

    /* PAY WITH USDC : 1 CROWD TOKEN => 1 USDC  */
    function buyTokenUSDC (uint256 amountUSDC) public payable returns (bool){//uint256 tokens
        require(mintingIsLive , "Minting is OFF LINE");
        require(amountUSDC > 0, "Not enough Tokens to buy");

        address _holder = msg.sender;
        if(!inRewardsPaused ) { 
            sendAndLiquify();
            processAccount(_holder, lastSentToContract);
        }

        //calculate token amount for tokenPriceUSDC and add 12 decimal from USDC deposit
        uint256 tokens = amountUSDC.mul(10 ** 12).mul(100).div(tokenPriceUSDC);

        require(totalSupply().add(tokens) <= MAX_SUPPLY,"MAX SUPPLY reached");

        setBuyTime(_holder);  //call before minting

        USDC.transferFrom(_holder, owner, amountUSDC);

        _mint(_holder,tokens);
        
        addCorrection(_holder,tokens);
        
        if(isLockupOn){
            if(lockedUntil[_holder]==0)lockedUntil[_holder] = block.timestamp + lockupTime;
        }       
        return true;
    }

/* 
    USED FOR:
    - send tokens PURCHASED BY BANK TRANSFER
    - deposit tokens into the presale contract
    */
    function mintTokenADMIN (address _holder, uint256 tokens) public payable returns (bool){
        require(allowedWallet[msg.sender] , "Not Admin");
        require(totalSupply().add(tokens) <= MAX_SUPPLY,"MAX SUPPLY reached");

        setBuyTime(_holder);  //call before minting

        _mint(_holder,tokens);
        
        addCorrection(_holder,tokens);
        
        if(isLockupOn){
            if(lockedUntil[_holder]==0)lockedUntil[_holder] = block.timestamp + lockupTime;
        }
        return true;
    }

/*  

ilBorgo token will entitle the holder to convert TOKENS into an equity financial instrument (SFP) *
that gives the right to participation in the profits of management and any capital gain on the future sale of real estate.
* KYC would be needed

*/
    function convertTokenToStocks (uint256 _tokens) public returns (bool ){
        address _holder = msg.sender;
  
        transfer(owner, _tokens);
 
        subCorrection(_holder,_tokens);
        totalRewardsCorrection = totalRewardsCorrection.sub(withdrawnRewards[_holder].add(paidRewards[_holder]));

        return true;
    }


    /* ADMIN FUNCTIONS TO MANAGE CROWD TOKEN CONTRACT BALANCE*/
    /* USDC CAN ONLY BE SENT ONLY TO PROJECT WALLET*/
    function withdrawUsdcFromContract(uint256 _amount) external  onlyOwner{
        require(USDC.balanceOf(address(this)) >= _amount, "Request exceed Balance");
        USDC.transfer(owner, _amount);
        withdrawns = withdrawns.add(_amount);
    }

    function withdrawUsdcFromContractAll() external  onlyOwner{
        USDC.transfer(owner, USDC.balanceOf(address(this)));
    }

    function depositUsdcToContract(uint256 _amount) external  {//onlyOwner
        // You need to approve this action from USDC contract before or transfer directly USDC to contract address
        USDC.transferFrom(msg.sender,address(this), _amount);
        deposits = deposits.add(_amount);
    }

    function withdrawTokenContract(address _token, uint256 _amount) external onlyOwner{
        IERC20(_token).transfer(owner, _amount);
    }

   
    /*  USED FOR ESTIMATE THE AMOUNT IN THE DAPP */
    function  getAmountOfTokenForEth(uint tokenIn) public virtual view returns (uint256){
      address[] memory path = new address[](2);
        path[1] = WETH;
        path[0] = address(USDC);
      uint[] memory amounts = uniswapV2Router.getAmountsIn(tokenIn,path);
        return amounts[0].mul(10 ** 12).mul(100).div(tokenPriceUSDC);
    }
    

    function swapEthToUsdcAndSendTo(uint256 amount, address _receiver) internal  returns(uint256) {
        if(amount<1)return 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(USDC);

        // make the swap
        uint[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: amount}(
            0, // accept any amount of USDC
            path,
            _receiver,
            block.timestamp + 30
        );
       return amounts[1];
    }
    
    /* in any case could be changed the WETH-USDC-BUSD contract address */
    function setTokenAddressUSDC(address _contract) public onlyOwner{
        USDC = IERC20(_contract);
    }

    function setTokenAddressWETH(address _contract) public onlyOwner{
        WETH = _contract;
    }

/* return contract infos */
    function contractInfo()
        public view returns (
            address _owner,
            string memory _name,
            string memory _symbol,
            uint256 _totalSupply,
            uint256 _totalRewardsDistributed,
            uint256 _rewardInterval,
            uint256 _rewardRate,
            uint256 _lastSentToContract,
            uint256 _totalDividendsDistributed
            ) {
_owner = owner;_name=name();_symbol=symbol();_totalSupply=totalSupply();
_totalRewardsDistributed=totalRewardsDistributed;
_totalDividendsDistributed=totalDividendsDistributed;
_rewardInterval=rewardInterval;_rewardRate=rewardRate;_lastSentToContract=lastSentToContract;
            }


//return account infos
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            uint256 balance,
            uint256 _totalRewards,
            uint256 _withdrawableRewards,
            uint256 _lastClaimTime,
            uint256 _nextClaimTime,
            uint256 _numClaims,
            uint256 _withdrawnDividends,
            uint256 _withdrableDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        balance = balanceOf(account);

        _withdrawableRewards = withdrawableRewardOf(account);
        
        _totalRewards = withdrawnRewards[account].add(rewardOfTime(account));// accumulativeDividendOf(account);

        _lastClaimTime = lastClaimTimes[account];

        _nextClaimTime = _lastClaimTime > 0 ?
                                    _lastClaimTime.add(rewardInterval) :
                                    0;

        _numClaims = numClaimsAccount[account];
        
        _withdrawnDividends = withdrawnDividends[account];

        _withdrableDividends = dividendsOf(account);

    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256 ,
            uint256 ,
            uint256 ,
            uint256 ,uint256 ,uint256 ,uint256 ,uint256 ,uint256 ) {


        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }
    

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

}