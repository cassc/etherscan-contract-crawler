// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./abstracts/Context.sol";
import "./libraries/SafeMath.sol";
import "./AdoToken.sol";
import "./interfaces/IBEP20.sol";

contract AdoAffiliates is Context {
	using SafeMath for uint256;

	address private _owner;
	struct ReferrerDetails { uint256 transactions; uint256 bonus; uint256 totalValue; uint256 commissions; }
	mapping(address => ReferrerDetails) private _referrers;
	uint256 private _minTxValue;
	uint256 private _referredSwaps;
	mapping(uint256 => uint256) private _bonusStructure;
	AdoToken public tokenContract;

	modifier onlyTokenContract() {
		require(_msgSender() == address(tokenContract), "AdoAffiliates: Only the token contract can call this function");
		_;
	}

	modifier onlyOwner() {
		require(_owner == _msgSender(), "AdoAffiliates: caller is not the owner");
		_;
	}

	constructor(AdoToken _tokenContract) {
		_owner = _msgSender();
		tokenContract = _tokenContract;
		_minTxValue = tokenContract.totalSupply().div(100000);
		_bonusStructure[5] = 1;
		_bonusStructure[20] = 2;
		_bonusStructure[50] = 4;
		_bonusStructure[100] = 6;
		_bonusStructure[250] = 9;
	}

	function owner() external view returns (address) {
		return _owner;
	}

	function referredSwaps() external view returns(uint256) {
		return _referredSwaps;
	}

	function minTxValue() external view returns(uint256) {
		return _minTxValue;
	}

	function referrerStats(address account) external view returns (uint256 transactions, uint256 bonus, uint256 totalValue, uint256 commissions) {
		transactions = _referrers[account].transactions;
		bonus = _referrers[account].bonus;
		totalValue = _referrers[account].totalValue;
		commissions = _referrers[account].commissions;
	}

	function payCommission(address referrer, uint256 amount, uint256 divider) external onlyTokenContract {
		if (amount >= _minTxValue) {
			_referrers[referrer].transactions++;
			uint256 commission = 1;
			if (_bonusStructure[_referrers[referrer].transactions] > _referrers[referrer].bonus) {
				_referrers[referrer].bonus = _bonusStructure[_referrers[referrer].transactions];
			}
			_referrers[referrer].totalValue = _referrers[referrer].totalValue.add(amount);
			commission = commission.add(_referrers[referrer].bonus);
			uint256 commissionValue = amount.div(100)
				.mul(commission)
				.div(divider);
			_referrers[referrer].commissions = _referrers[referrer].commissions.add(commissionValue);
			tokenContract.transfer(referrer, commissionValue);
			_referredSwaps++;
		}
	}

	function updateMinTxValue(uint256 newValue) external onlyTokenContract {
		_minTxValue = newValue;
	}

	function burnTheHouseDown() external onlyTokenContract returns (uint256) {
		uint256 balance = tokenContract.balanceOf(address(this));
		tokenContract.transfer(0x000000000000000000000000000000000000dEaD, balance);
		return balance;
	}

	function addV2Comissions(address referrer, uint256 transactions, uint256 totalValue, uint256 commissions) external onlyOwner {
		require(!tokenContract.swapEnabled(), "AdoAffiliates: V3 is public");
		_referrers[referrer].transactions = transactions;
		_referrers[referrer].totalValue = totalValue;
		_referrers[referrer].commissions = commissions;
		if (transactions >= 250) _referrers[referrer].bonus = _bonusStructure[250];
		if (_referrers[referrer].bonus == 0 && transactions >= 100) _referrers[referrer].bonus = _bonusStructure[100];
		if (_referrers[referrer].bonus == 0 && transactions >= 50) _referrers[referrer].bonus = _bonusStructure[50];
		if (_referrers[referrer].bonus == 0 && transactions >= 20) _referrers[referrer].bonus = _bonusStructure[20];
		if (_referrers[referrer].bonus == 0 && transactions >= 5) _referrers[referrer].bonus = _bonusStructure[5];
		_referredSwaps = _referredSwaps.add(transactions);
	}
}