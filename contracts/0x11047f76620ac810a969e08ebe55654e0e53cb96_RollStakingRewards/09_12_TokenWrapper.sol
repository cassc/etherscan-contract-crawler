// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/math/SafeMath.sol";
import "./openzeppelin/token/ERC20/SafeERC20.sol";

contract TokenWrapper {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public token;

	uint256 internal _totalSupply;
	mapping(address => uint256) internal _balances;

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view returns (uint256) {
		return _balances[account];
	}

	function stake(uint256 amount) public virtual {
		_totalSupply = _totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		token.safeTransferFrom(msg.sender, address(this), amount);
	}

	function withdraw(uint256 amount) public virtual {
		_totalSupply = _totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		token.safeTransfer(msg.sender, amount);
	}
}