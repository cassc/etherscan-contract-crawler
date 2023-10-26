// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;

import {Context} from "../../dependencies/openzeppelin/contracts/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IAaveIncentivesController} from "../../interfaces/IAaveIncentivesController.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20, IERC20Metadata {
	using SafeMath for uint256;

	mapping(address => uint256) internal _balances;

	mapping(address => mapping(address => uint256)) private _allowances;
	uint256 internal _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;

	ILendingPool internal _pool;
	address internal _underlyingAsset;

	constructor(string memory name_, string memory symbol_, uint8 decimals_) {
		_name = name_;
		_symbol = symbol_;
		_decimals = decimals_;
	}

	/**
	 * @return The name of the token
	 **/
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @return The symbol of the token
	 **/
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @return The decimals of the token
	 **/
	function decimals() public view returns (uint8) {
		return _decimals;
	}

	/**
	 * @return The total supply of the token
	 **/
	function totalSupply() public view virtual returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @return The balance of the token
	 **/
	function balanceOf(address account) public view virtual returns (uint256) {
		return _balances[account];
	}

	/**
	 * @return Abstract function implemented by the child aToken/debtToken.
	 * Done this way in order to not break compatibility with previous versions of aTokens/debtTokens
	 **/
	function _getIncentivesController() internal view virtual returns (IAaveIncentivesController);

	/**
	 * @dev Executes a transfer of tokens from _msgSender() to recipient
	 * @param recipient The recipient of the tokens
	 * @param amount The amount of tokens being transferred
	 * @return `true` if the transfer succeeds, `false` otherwise
	 **/
	function transfer(address recipient, uint256 amount) public virtual returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		emit Transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev Returns the allowance of spender on the tokens owned by owner
	 * @param owner The owner of the tokens
	 * @param spender The user allowed to spend the owner's tokens
	 * @return The amount of owner's tokens spender is allowed to spend
	 **/
	function allowance(address owner, address spender) public view virtual returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev Allows `spender` to spend the tokens owned by _msgSender()
	 * @param spender The user allowed to spend _msgSender() tokens
	 * @return `true`
	 **/
	function approve(address spender, uint256 amount) public virtual returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
	 * @param sender The owner of the tokens
	 * @param recipient The recipient of the tokens
	 * @param amount The amount of tokens being transferred
	 * @return `true` if the transfer succeeds, `false` otherwise
	 **/
	function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
		);
		emit Transfer(sender, recipient, amount);
		return true;
	}

	/**
	 * @dev Increases the allowance of spender to spend _msgSender() tokens
	 * @param spender The user allowed to spend on behalf of _msgSender()
	 * @param addedValue The amount being added to the allowance
	 * @return `true`
	 **/
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	/**
	 * @dev Decreases the allowance of spender to spend _msgSender() tokens
	 * @param spender The user allowed to spend on behalf of _msgSender()
	 * @param subtractedValue The amount being subtracted to the allowance
	 * @return `true`
	 **/
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
		);
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

		if (address(_getIncentivesController()) != address(0)) {
			// uint256 currentTotalSupply = _totalSupply;
			_getIncentivesController().handleActionBefore(sender);
			if (sender != recipient) {
				_getIncentivesController().handleActionBefore(recipient);
			}
		}

		_balances[sender] = senderBalance;
		uint256 recipientBalance = _balances[recipient].add(amount);
		_balances[recipient] = recipientBalance;

		if (address(_getIncentivesController()) != address(0)) {
			uint256 currentTotalSupply = _totalSupply;
			_getIncentivesController().handleActionAfter(sender, _balances[sender], currentTotalSupply);
			if (sender != recipient) {
				_getIncentivesController().handleActionAfter(recipient, _balances[recipient], currentTotalSupply);
			}
		}
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		uint256 currentTotalSupply = _totalSupply.add(amount);
		uint256 accountBalance = _balances[account].add(amount);
		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionBefore(account);
		}
		_totalSupply = currentTotalSupply;
		_balances[account] = accountBalance;
		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionAfter(account, accountBalance, currentTotalSupply);
		}
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 currentTotalSupply = _totalSupply.sub(amount);
		uint256 accountBalance = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");

		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionBefore(account);
		}

		_totalSupply = currentTotalSupply;
		_balances[account] = accountBalance;

		if (address(_getIncentivesController()) != address(0)) {
			_getIncentivesController().handleActionAfter(account, accountBalance, currentTotalSupply);
		}
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _setName(string memory newName) internal {
		_name = newName;
	}

	function _setSymbol(string memory newSymbol) internal {
		_symbol = newSymbol;
	}

	function _setDecimals(uint8 newDecimals) internal {
		_decimals = newDecimals;
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

	function getAssetPrice() external view returns (uint256) {
		ILendingPoolAddressesProvider provider = _pool.getAddressesProvider();
		address oracle = provider.getPriceOracle();
		return IPriceOracle(oracle).getAssetPrice(_underlyingAsset);
	}
}