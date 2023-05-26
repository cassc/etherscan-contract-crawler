// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IIMT {
	function reinvestReflections(address account, uint256 minTokens) external payable;
}

contract IMTRewardToken is ERC20, Ownable {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;

	uint256 internal constant magnitude = 2**128;
	uint256 internal magnifiedDividendPerShare;
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;
	uint256 public totalDividendsDistributed;

	IIMT public iimt;
	mapping(address => bool) public excludedFromDividends;
	event ExcludeFromDividends(address indexed account);
	event DividendsDistributed(address indexed from, uint256 weiAmount);
	event DividendWithdrawn(address indexed to, uint256 weiAmount, address received);

	constructor(
		string memory _name,
		string memory _symbol,
		address _iimt
	) ERC20(_name, _symbol) {
		iimt = IIMT(_iimt);
	}

	receive() external payable {
		distributeDividends();
	}

	function distributeDividends() public payable {
		require(totalSupply() > 0);

		if (msg.value > 0) {
			magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
			emit DividendsDistributed(msg.sender, msg.value);
			totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
		}
	}

	function withdrawDividend() public virtual {
		_withdrawDividendOfUser(payable(msg.sender));
	}

	function reinvestDividend(uint256 minTokens) public {
		_reinvestDividend(payable(msg.sender), minTokens);
	}

	function _withdrawDividendOfUser(address payable user) internal {
		uint256 _withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
			(bool success, ) = user.call{ value: _withdrawableDividend, gas: 3000 }("");
			if (!success) {
				withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
			}
		}
	}

	function _reinvestDividend(address payable user, uint256 minTokens) internal {
		uint256 _withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
			iimt.reinvestReflections{ value: _withdrawableDividend }(user, minTokens);
		}
	}

	function dividendOf(address _owner) public view returns (uint256) {
		return withdrawableDividendOf(_owner);
	}

	function withdrawableDividendOf(address _owner) public view returns (uint256) {
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}

	function withdrawnDividendOf(address _owner) public view returns (uint256) {
		return withdrawnDividends[_owner];
	}

	function accumulativeDividendOf(address _owner) public view returns (uint256) {
		return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) internal virtual override {
		require(false, "No transfers allowed");
	}

	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	function setBalance(address payable account, uint256 newBalance) external {
		require(msg.sender == address(iimt), "Only callable by token");
		if (excludedFromDividends[account]) {
			return;
		}
		_setBalance(account, newBalance);
	}

	function _setBalance(address account, uint256 newBalance) internal {
		uint256 currentBalance = balanceOf(account);

		if (newBalance > currentBalance) {
			uint256 mintAmount = newBalance.sub(currentBalance);
			_mint(account, mintAmount);
		} else if (newBalance < currentBalance) {
			uint256 burnAmount = currentBalance.sub(newBalance);
			_burn(account, burnAmount);
		}
	}

	function excludeFromDividends(address account) external onlyOwner {
		require(!excludedFromDividends[account]);
		excludedFromDividends[account] = true;
		_setBalance(account, 0);
		emit ExcludeFromDividends(account);
	}

	function includeInDividends(address account) external onlyOwner {
		require(excludedFromDividends[account]);
		excludedFromDividends[account] = false;
	}

	function setToken(address _imt) external onlyOwner {
		iimt = IIMT(_imt);
	}

	function accountInfo(address account)
		external
		view
		returns (
			uint256 withdrawable,
			uint256 withdrawn,
			uint256 balance
		)
	{
		withdrawable = withdrawableDividendOf(account);
		withdrawn = withdrawnDividendOf(account);
		balance = balanceOf(account);
	}
}