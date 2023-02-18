/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}

library ContractUnti {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}


library DFS_Model {

    address public constant _blackAddr = 0x0000000000000000000000000000000000000001;
    uint256 public constant MAX_INT = 2**256 - 1;

    // user
    struct User {
        address addr;
        address inviterAddr;
    }

    // level
    struct Level  {
        uint256 level;     
        uint256 commission;
    }
}



interface IDFSUser {
    function bindInviter(address inviterAddr) external returns(bool);
    function bindInviter(address msgAddr,address inviterAddr) external returns(bool);
    function getInviterUserByAddr(address userAddr) external view returns(address);
    function existUser(address userAddr) external view returns(bool);
}

interface ILottery {
    function swapInvest() external;
}


interface ILotteryLp {
    function swapLpInvest() external;
}

contract BaseConfig is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IDFSUser private _iDFSUser;
    ILotteryLp private _ilotteryLp;
    ILottery private _ilottery;

    bool private _isOpenSwap;

    address[] private uniswapBuyBlackArray;
    address[] private uniswapSellBlackArray;
    address[] private uniswapWhiteArray;

    uint256 private _deflationBalances = 3000 *10**18;
	uint256 private _holdBalances = 1 *10**18;
	uint256 private _lplottleLimit = 100 *10**18;
	uint256 private _marketLottleLimit = 100 *10**18;

    uint256 private _lockTime = 30 days; 
    // uint256 private _lockTime = 10 minutes;
    uint256 private _deleteLPFee = 99;

	uint256 private _incomeNet1 = 50;
	uint256 private _incomeNet2 = 30;
	uint256 private _incomeNet3 = 20;

    address private _marketAddrReal;
	address private _marketAddr;
	address private _lpAddr;

    IUniswapV2Pair private _uniswapV2UsdtPair;
    address private _uniswapV2Pair;

    constructor(IDFSUser iDFSUser) {
        require(address(iDFSUser) != address(0), "Invalid iDFSUser");
        _iDFSUser = iDFSUser;

        // add whitelist
        _push(0x9845d8d405263020A7FceF14334630cc8b3030e2);
        _push(0xf2531CAaB848b49600Ddf4A8E76Ae6bF9d64e137);
        _push(0x54119D999B8778E6C83BdbE0323075b72CCB7067);
        _push(0x555d3cd428C637Bb4F44E135Fc96B5397A88fF85);
        _push(0x5adb3e8bfEF493Eb1Ee21a25E6706f9c81bBEc67);
        _push(0xDF6d43186848370A3C0d10768180831256C4dB27);
        _push(0x60BC71125B3F9177B3a60759977935fD485EF546);
        _push(0xE73F970B9caD47c62fF937CccAb3Ca55905DE61E);
    }

    function setIDFSUser(IDFSUser iDFSUser) private {
        require(address(_iDFSUser) != address(0), "Invalid _iDFSUser");
        _iDFSUser = iDFSUser;
    }

    function queryIDFSUser() public view returns(IDFSUser){
       return _iDFSUser;
    }

    function setIsOpenSwap(bool isOpen) private {
        _isOpenSwap = isOpen;
    }

    function queryIsOpenSwap() public view returns(bool){
       return _isOpenSwap;
    }

    function setDeleteLPFee(uint256 _fee) private {
        _deleteLPFee = _fee;
    }

    function queryDeleteLPFee() public view returns(uint256){
       return _deleteLPFee;
    }

    function setLockTime(uint256 lockTime) private {
        _lockTime = lockTime;
    }

    function queryLockTime() public view returns(uint256){
       return _lockTime;
    }

    function setMarketAddr(address addr) private {
        _marketAddr = addr;
    }

    function queryMarketAddr() public view returns(address){
       return _marketAddr;
    }

    function setMarketAddrReal(address addr) private {
        _marketAddrReal = addr;
    }

    function queryMarketAddrReal() public view returns(address){
       return _marketAddrReal;
    }

    function setLPAddr(address addr) private {
        _lpAddr = addr;
    }

    function queryLPAddr() public view returns(address){
       return _lpAddr;
    }

    function seteLotteryLp(ILotteryLp ilotteryLp) private {
        require(address(ilotteryLp) != address(0), "Invalid ilotteryLp");
        _ilotteryLp = ilotteryLp;
    }

    function queryeLotteryLp() public view returns(ILotteryLp){
       return _ilotteryLp;
    }

    function seteLottery(ILottery ilottery) private {
        require(address(ilottery) != address(0), "Invalid ilottery");
        _ilottery = ilottery;
    }

    function queryeLottery() public view returns(ILottery){
       return _ilottery;
    }

    function seteDeflationBalances(uint256 deflationBalances) private {
        _deflationBalances = deflationBalances;
    }

    function queryeDeflationBalances() public view returns(uint256){
       return _deflationBalances;
    }

    function seteHoldBalances(uint256 holdBalances) private {
        _holdBalances = holdBalances;
    }

    function queryeHoldBalances() public view returns(uint256){
       return _holdBalances;
    }
    function seteLplottleLimit(uint256 lplottleLimit) private {
        _lplottleLimit = lplottleLimit;
    }

    function queryeLplottleLimit() public view returns(uint256){
       return _lplottleLimit;
    }

    function seteMarketLottleLimit(uint256 marketLottleLimit) private {
        _marketLottleLimit = marketLottleLimit;
    }

    function queryeMarketLottleLimit() public view returns(uint256){
       return _marketLottleLimit;
    }

    function seteIncomeNet1(uint256 incomeNet1) private {
        _incomeNet1 = incomeNet1;
    }

    function queryeIncomeNet1() public view returns(uint256){
       return _incomeNet1;
    }

    function seteIncomeNet2(uint256 incomeNet2) private {
        _incomeNet2 = incomeNet2;
    }

    function queryeIncomeNet2() public view returns(uint256){
       return _incomeNet2;
    }

    function seteIncomeNet3(uint256 incomeNet3) private {
        _incomeNet3 = incomeNet3;
    }

    function queryeIncomeNet3() public view returns(uint256){
       return _incomeNet3;
    }

    function _getIndex(address addr,address[] memory array) public pure returns (uint){
        if(addr == address(0)){
            return DFS_Model.MAX_INT;
        }
        for(uint i = 0;i < array.length; i++){
            if(addr == array[i]){
                return i;
            }
        }
        return DFS_Model.MAX_INT;
    }

    function _push(address addr) private returns(bool){
        if(_getIndex(addr,uniswapWhiteArray) == DFS_Model.MAX_INT){
            uniswapWhiteArray.push(addr);
            return true;
        }
        return false;
    }

    function _remove(address addr)private returns(bool){
        if(addr == address(0)){
            return false;
        }
        uint index = _getIndex(addr,uniswapWhiteArray);
        if(index >= uniswapWhiteArray.length){
            return false;
        }
        uniswapWhiteArray[index]=uniswapWhiteArray[uniswapWhiteArray.length-1];
        uniswapWhiteArray.pop();
        return true;
    }

    function getUniswapWhiteArray() public view returns(address[] memory){
        return uniswapWhiteArray;
    }

    function _pushBuy(address addr) private returns(bool){
        if(_getIndex(addr,uniswapBuyBlackArray) == DFS_Model.MAX_INT){
            uniswapBuyBlackArray.push(addr);
            return true;
        }
        return false;
    }

    function _removeBuy(address addr)private returns(bool){
        if(addr == address(0)){
            return false;
        }
        uint index = _getIndex(addr,uniswapBuyBlackArray);
        if(index >= uniswapBuyBlackArray.length){
            return false;
        }
        uniswapBuyBlackArray[index]=uniswapBuyBlackArray[uniswapBuyBlackArray.length-1];
        uniswapBuyBlackArray.pop();
        return true;
    }

    function getUniswapBuyBlackArray() public view returns(address[] memory){
        return uniswapBuyBlackArray;
    }

    function _pushSell(address addr) private returns(bool){
        if(_getIndex(addr,uniswapSellBlackArray) == DFS_Model.MAX_INT){
            uniswapSellBlackArray.push(addr);
            return true;
        }
        return false;
    }

    function _removeSell(address addr)private returns(bool){
        if(addr == address(0)){
            return false;
        }
        uint index = _getIndex(addr,uniswapSellBlackArray);
        if(index >= uniswapSellBlackArray.length){
            return false;
        }
        uniswapSellBlackArray[index]=uniswapSellBlackArray[uniswapSellBlackArray.length-1];
        uniswapSellBlackArray.pop();
        return true;
    }

    function getUniswapSellBlackArray() public view returns(address[] memory){
        return uniswapSellBlackArray;
    }

}

contract DFS_3_0 is IERC20, Ownable {
	using SafeMath for uint256;
    using Address for address;

    BaseConfig private _baseConfig;
    address private tokenHiveAddr = 0x3C7d3939fd3A2E0fF6316B07A5D0549B1F37A0bb;
	mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
	uint256 private constant _allBalances = 9000 *10**18;
    string private _name = "Future Star";
    string private _symbol = "FST";
    uint8 private _decimals = 18;
    address[] private LpList;
    mapping(uint256 => DFS_Model.Level) private levelMap;

    mapping(address => uint256) private userAddLPTime;
    uint256 private _liqBuyNetIncome = 3;
	uint256 private constant _liqBuyMarketing = 1;
	uint256 private constant _liqSellLP = 2;
	uint256 private _liqSellBlack = 1;
	uint256 private constant _liqSellMarket = 1;
	
    IERC20 public constant usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address private _uniswapV2Pair;
	IUniswapV2Pair private _uniswapV2UsdtPair;
	mapping(address => bool) private _isSetUniswapV2UsdtPair;
    
	//to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

	constructor(BaseConfig baseConfig) {
        require(address(baseConfig) != address(0), "Invalid baseConfig");
        _baseConfig = baseConfig;
        _balances[tokenHiveAddr] = _allBalances;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
            // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );
        // Create a uniswap pair for this new token
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(_uniswapV2Router.WETH(),address(this));
        // _isSetUniswapV2UsdtPair[address(_uniswapV2Pair)] = true;

        _uniswapV2UsdtPair = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this),address(usdt)));
        // //exclude owner and this contract from fee
        _isSetUniswapV2UsdtPair[address(_uniswapV2UsdtPair)] = true;

        levelMap[0] = DFS_Model.Level({
            level: 0,
            commission: _baseConfig.queryeIncomeNet1()
        });
        levelMap[1] = DFS_Model.Level({
            level: 1,
            commission: _baseConfig.queryeIncomeNet2()
        });
        levelMap[2] = DFS_Model.Level({
            level: 2,
            commission: _baseConfig.queryeIncomeNet3()
        });

        emit Transfer(address(0), tokenHiveAddr, _allBalances);
    }
	
	function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _allBalances;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }
	
	function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function _takeLiquidity(address fromAddress,address toAddress,uint256 tLiquidityFee ,uint256 amount,uint8 tpl ) private {
        if(tpl == 1 ){
            // sell
            uint256 _liqSellLPFee = calcRatio(amount,_liqSellLP);
            _balances[_baseConfig.queryLPAddr()] = _balances[_baseConfig.queryLPAddr()].add(_liqSellLPFee);
            emit Transfer(fromAddress, _baseConfig.queryLPAddr(), _liqSellLPFee);

            uint256 _liqSellMarketFee = calcRatio(amount,_liqSellMarket);
            _balances[_baseConfig.queryMarketAddr()] = _balances[_baseConfig.queryMarketAddr()].add(_liqSellMarketFee);
            emit Transfer(fromAddress, _baseConfig.queryMarketAddr(), _liqSellMarketFee);

            if(tLiquidityFee == 4 && _liqSellBlack > 0){
                uint256 _liqSellBlackFee = calcRatio(amount,_liqSellBlack);
                _balances[DFS_Model._blackAddr] = _balances[DFS_Model._blackAddr].add(_liqSellBlackFee);
                emit Transfer(fromAddress, DFS_Model._blackAddr, _liqSellBlackFee);
            }
        }else if(tpl == 2) {
            // buy
            uint256 _liqBuyMarketingFee = calcRatio(amount,_liqBuyMarketing);
            _balances[_baseConfig.queryMarketAddr()] = _balances[_baseConfig.queryMarketAddr()].add(_liqBuyMarketingFee);
            emit Transfer(fromAddress, _baseConfig.queryMarketAddr(), _liqBuyMarketingFee);

            if(tLiquidityFee == 4 && _liqBuyNetIncome > 0){
                uint256 _liqBuyNetIncomeFee = calcRatio(amount,_liqBuyNetIncome);
                bool isBindFrom = _baseConfig.queryIDFSUser().existUser(toAddress);
                if(!isBindFrom){
                    _balances[DFS_Model._blackAddr] = _balances[DFS_Model._blackAddr].add(_liqBuyNetIncomeFee);
                    emit Transfer(fromAddress, DFS_Model._blackAddr, _liqBuyNetIncomeFee);
                }else{
                    address curAddr = toAddress;
                    uint256 _liqBuyNetIncomeFeeAll =0;
                    for(uint  i = 0; i < 3 ; i++){
                        address inviterAddr = _baseConfig.queryIDFSUser().getInviterUserByAddr(curAddr);
                        if(inviterAddr == address(0)){
                            break;
                        }
                        uint256 customTokenBalance = _balances[inviterAddr];
                        if(customTokenBalance >= _baseConfig.queryeHoldBalances()){
                            uint256 _liqBuyNetIncomeFeeTmp = calcRatio(_liqBuyNetIncomeFee,levelMap[i].commission);
                            _balances[inviterAddr] = _balances[inviterAddr].add(_liqBuyNetIncomeFeeTmp);
                            _liqBuyNetIncomeFeeAll = _liqBuyNetIncomeFeeAll.add(_liqBuyNetIncomeFeeTmp);
                            emit Transfer(fromAddress, inviterAddr, _liqBuyNetIncomeFeeTmp);
                        }
                        curAddr = inviterAddr;
                    }
                    if(_liqBuyNetIncomeFeeAll == 0){
                        _balances[DFS_Model._blackAddr] = _balances[DFS_Model._blackAddr].add(_liqBuyNetIncomeFee);
                        emit Transfer(fromAddress, DFS_Model._blackAddr, _liqBuyNetIncomeFee);
                    }else{
                        if(_liqBuyNetIncomeFee.sub(_liqBuyNetIncomeFeeAll) > 0){
                            _balances[DFS_Model._blackAddr] = _balances[DFS_Model._blackAddr].add(_liqBuyNetIncomeFee.sub(_liqBuyNetIncomeFeeAll));
                            emit Transfer(fromAddress, DFS_Model._blackAddr, _liqBuyNetIncomeFee.sub(_liqBuyNetIncomeFeeAll));
                        }
                    }
                }
            }
        }
    }
	
	function calcRatio(uint256 amount,uint256 liquidityFee)
        private
        pure
        returns (uint256)
    {
        return amount.mul(liquidityFee).div(10**2);
    }

    function calcRetain(uint256 amount)
        private
        pure
        returns (uint256)
    {
        return amount.mul(1).div(10**4);
    }
	
	function _getValues(uint256 tAmount,uint256 _liquidityFee)
        private
        pure
        returns (
            uint256,
            uint256
        )
    {
        uint256 tLiquidity = calcRatio(tAmount,_liquidityFee);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }
	
	function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // The entire network is deflated to 3,000, buy 3% of the network income, sell 1% of the black hole destruction, return to zero
        uint256 blackAddrBanlance = balanceOf(DFS_Model._blackAddr);
        if( (blackAddrBanlance >= _allBalances.sub(_baseConfig.queryeDeflationBalances())) && _liqBuyNetIncome != 0 ){
            _liqBuyNetIncome = 0;
            _liqSellBlack = 0;
        }

		bool isAdd = false;
        bool isDel = false;
        uint8 tpl = 10;
        uint256 tLiquidityFee = 0 ;
		if(to == address(_uniswapV2UsdtPair)) 
		{
            tpl = 0;
            (isAdd,) = getLPStatus(from,to);
            if(!isAdd){
                require(_baseConfig.queryIsOpenSwap(), "Whether to open the main switch for buying and selling"); 
                require(_baseConfig._getIndex(from,_baseConfig.getUniswapBuyBlackArray()) == DFS_Model.MAX_INT, "Sell blacklist");
                if(_baseConfig._getIndex(from,_baseConfig.getUniswapWhiteArray()) == DFS_Model.MAX_INT){
                    tpl = 1;
                    tLiquidityFee = _liqSellLP.add(_liqSellBlack).add(_liqSellMarket);
                    // One ten-thousandth is automatically reserved when selling coins
                    amount = amount.sub(calcRetain(amount));
                }
            }else{
                _push(from);
                userAddLPTime[from] = block.timestamp;
            }
		}
        bool isLPLocking = false;
        if(from == address(_uniswapV2UsdtPair)) 
		{
            tpl = 0;
            (,isDel) = getLPStatus(from,to);
            if(!isDel){
                require(_baseConfig.queryIsOpenSwap(), "Whether to open the main switch for buying and selling"); 
                require(_baseConfig._getIndex(to,_baseConfig.getUniswapBuyBlackArray()) == DFS_Model.MAX_INT, "Buy blacklist");
                if(_baseConfig._getIndex(to,_baseConfig.getUniswapWhiteArray()) == DFS_Model.MAX_INT){
                    tpl = 2;
                    tLiquidityFee = _liqBuyNetIncome.add(_liqBuyMarketing);
                }
            }else{
                _remove(to);
                uint256 userTime = userAddLPTime[to];
                userAddLPTime[to] = 0;
                isLPLocking = userTime.add(_baseConfig.queryLockTime()) >= block.timestamp;
            }
		}
        
        // Automatic binding relationship
        if(_baseConfig.queryIDFSUser().existUser(from) && (!_baseConfig.queryIDFSUser().existUser(to)) && (!ContractUnti.isContract(to)) && tpl == 10 ){
            _baseConfig.queryIDFSUser().bindInviter(to,from);
        }

        // transfer amount, liquidity fee
        if(!isLPLocking){
            _tokenTransfer(from, to, amount, tLiquidityFee,tpl);
        }else{
            _tokenTransfer(from, to, amount);
        }

        if(tpl == 10){
            _swap();
        }
        
    }
	
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
		uint256 tLiquidityFee,
        uint8 tpl
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(amount,tLiquidityFee);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        if (tLiquidity > 0) _takeLiquidity(sender,recipient,tLiquidityFee,amount,tpl);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(amount,_baseConfig.queryDeleteLPFee());

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);

        _balances[_baseConfig.queryMarketAddrReal()] = _balances[_baseConfig.queryMarketAddrReal()].add(tFee);
        emit Transfer(sender, _baseConfig.queryMarketAddrReal(), tFee);
    }

    function _swap() private {
        // When the LP pool reaches the specified number, it will start to distribute dividends
        if(balanceOf(_baseConfig.queryLPAddr()) >= _baseConfig.queryeLplottleLimit() && address(_baseConfig.queryeLotteryLp()) != address(0)){
            _baseConfig.queryeLotteryLp().swapLpInvest();
        }
        // The marketing management pool reaches the specified number and starts to distribute dividends
        if(balanceOf(_baseConfig.queryMarketAddr()) >= _baseConfig.queryeMarketLottleLimit() && address(_baseConfig.queryeLottery()) != address(0)){
            _baseConfig.queryeLottery().swapInvest();
        }
    }

    function getLPStatus(address from,address to) internal view  returns (bool isAdd,bool isDel){
        IUniswapV2Pair pair;
        address token = address(this);
        if(_isSetUniswapV2UsdtPair[to]){
            pair = IUniswapV2Pair(to);
        }else{
            pair = IUniswapV2Pair(from);
        }
        isAdd = false;
        isDel = false;
        address token0 = pair.token0();
        address token1 = pair.token1();
        (uint r0,uint r1,) = pair.getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(pair));
        uint bal0 = IERC20(token0).balanceOf(address(pair));
        if (_isSetUniswapV2UsdtPair[to]) {
            if (token0 == token) {
                if (bal1 > r1) {
                    uint change1 = bal1 - r1;
                    isAdd = change1 > 1000;
                }
            } else {
                if (bal0 > r0) {
                    uint change0 = bal0 - r0;
                    isAdd = change0 > 1000;
                }
            }
        }else {
            if (token0 == token) {
                if (bal1 < r1 && r1 > 0) {
                    uint change1 = r1 - bal1;
                    isDel = change1 > 0;
                }
            } else {
                if (bal0 < r0 && r0 > 0) {
                    uint change0 = r0 - bal0;
                    isDel = change0 > 0;
                }
            }
        }
        return (isAdd,isDel);
    }

    function queryLiqBuyNetIncome() public view onlyOwner returns(uint256){
       return _liqBuyNetIncome;
    }

    function queryLiqSellBlack() public view onlyOwner returns(uint256){
       return _liqSellBlack;
    }

    function queryeUserAddLPTime(address addr) public view returns(uint256){
       return userAddLPTime[addr];
    }

    function seteUserAddLPTime(address addr,uint256 _time) public onlyOwner{
        require(addr != address(0), "Invalid addr");
        userAddLPTime[addr] = _time;
    }

    function queryUniswapV2Pair() public view onlyOwner returns(address){
       return _uniswapV2Pair;
    }

    function queryUniswapV2USDTPair() public view returns(IUniswapV2Pair){
       return _uniswapV2UsdtPair;
    }

    function queryeBaseConfig() public view returns(BaseConfig){
       return _baseConfig;
    }

    function seteBaseConfig(BaseConfig baseConfig) public onlyOwner{
        require(address(baseConfig) != address(0), "Invalid baseConfig");
        _baseConfig = baseConfig;
    }

    function _push(address addr) private returns(bool){
        if(_getIndex(addr) == DFS_Model.MAX_INT){
            LpList.push(addr);
            return true;
        }
        return false;
    }

    function _remove(address addr)private returns(bool){
        if(addr == address(0)){
            return false;
        }
        uint index = _getIndex(addr);
        if(index >= LpList.length){
            return false;
        }
        LpList[index]=LpList[LpList.length-1];
        LpList.pop();
        return true;
    }

    function _getIndex(address addr) private view returns (uint){
        if(addr == address(0)){
            return DFS_Model.MAX_INT;
        }
        for(uint i = 0;i < LpList.length; i++){
            if(addr == LpList[i]){
                return i;
            }
        }
        return DFS_Model.MAX_INT;
    }

    function getLpArray() public view returns(address[] memory){
        return LpList;
    }

}