// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { MasterChef } from "./MasterChef.sol";

interface Bitcorn
{
	function rewardToken() external view returns (address _rewardToken);

	function claim() external;
}

contract BitcornWrapperToken is Initializable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		bool exists;
		uint256 shares;
		uint256 rewardDebt;
		uint256 unclaimedReward;
	}

	address constant MASTER_CHEF = 0x8BAB23A24430E82C9D384F2996e1671f3e64869a;
	address constant WRAPPER_TOKEN_BRIDGE = 0x0DC52B853030E587eb10b11cfF7d5FDdFA594E71;

	address public token;
	address public rewardToken;

	uint256 public totalReward = 0;
	uint256 public accRewardPerShare = 0;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	uint256 public pid;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	constructor(address _token, uint256 _pid)
		ERC20("", "")
	{
		initialize(_token, _pid);
	}

	function name() public pure override returns (string memory _name)
	{
		return "Bitcorn-Like Wrapper Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "BLWT";
	}

	function initialize(address _token, uint256 _pid) public initializer
	{
		totalReward = 0;
		accRewardPerShare = 0;

		token = _token;
		rewardToken = Bitcorn(_token).rewardToken();
		pid = _pid;
	}
/*
	function migrate() external
	{
		require(pid == 0, "invalid state");
		pid = 72; // BITCORN
	}
*/
	function totalReserve() public view returns (uint256 _totalReserve)
	{
		return IERC20(token).balanceOf(address(this));
	}

	function deposit(uint256 _amount) external returns (uint256 _shares)
	{
		return deposit(_amount, msg.sender);
	}

	function deposit(uint256 _amount, address _account) public nonReentrant returns (uint256 _shares)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			uint256 _newTotalReserve = totalReserve();
			_amount = _newTotalReserve - _totalReserve;
			_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
			_mint(msg.sender, _shares);
		}
		_updateAccount(_account, int256(_shares));
		emit Deposit(_account, _shares);
		return _shares;
	}

	function withdraw(uint256 _shares) external returns (uint256 _amount)
	{
		return withdrawTo(_shares, msg.sender);
	}

	function withdrawTo(uint256 _shares, address _to) public nonReentrant returns (uint256 _amount)
	{
		_claimRewards();
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			_amount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
			_burn(msg.sender, _shares);
			IERC20(token).safeTransfer(_to, _amount);
		}
		_updateAccount(msg.sender, -int256(_shares));
		_sync(msg.sender);
		emit Withdraw(msg.sender, _shares);
		return _amount;
	}

	function withdraw(uint256 _shares, address _account) public nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			_amount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
			_burn(msg.sender, _shares);
			IERC20(token).safeTransfer(msg.sender, _amount);
		}
		_updateAccount(_account, -int256(_shares));
		_sync(_account);
		emit Withdraw(_account, _shares);
		return _amount;
	}

	function claim() external returns (uint256 _rewardAmount)
	{
		return claim(msg.sender);
	}

	function claim(address _account) public nonReentrant returns (uint256 _rewardAmount)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		_updateAccount(_account, 0);
		{
			AccountInfo storage _accountInfo = accountInfo[_account];
			_rewardAmount = _accountInfo.unclaimedReward;
			_accountInfo.unclaimedReward = 0;
		}
		if (_rewardAmount > 0) {
			totalReward -= _rewardAmount;
			IERC20(rewardToken).safeTransfer(_account, _rewardAmount);
		}
		emit Claim(_account, _rewardAmount);
		return _rewardAmount;
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _shares) internal override
	{
		if (_from == address(0) || _to == address(0)) return;
		if (msg.sender == MASTER_CHEF && (_from == MASTER_CHEF || _to == MASTER_CHEF || _from == WRAPPER_TOKEN_BRIDGE || _to == WRAPPER_TOKEN_BRIDGE)) return;
		_claimRewards();
		_updateAccount(_from, -int256(_shares));
		_updateAccount(_to, int256(_shares));
	}

	function syncAll() external nonReentrant
	{
		_claimRewards();
		for (uint256 _i = 0; _i < accountIndex.length; _i++) {
			_sync(accountIndex[_i]);
		}
	}

	function _sync(address _account) internal
	{
		address _bankroll = MasterChef(MASTER_CHEF).bankroll();
		if (_account == _bankroll) return;
		(address _token,,,,,,,) = MasterChef(MASTER_CHEF).poolInfo(pid);
		require(_token == address(this), "invalid pid");
		uint256 _balance = balanceOf(_account);
		(uint256 _stake,,) = MasterChef(MASTER_CHEF).userInfo(pid, _account);
		uint256 _shares = _balance + _stake;
		if (accountInfo[_account].shares <= _shares) return;
		uint256 _excess = accountInfo[_account].shares - _shares;
		if (_excess == 0) return;
		_updateAccount(_account, -int256(_excess));
		_updateAccount(_bankroll, int256(_excess));
	}

	function _updateAccount(address _account, int256 _shares) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}
		if (_accountInfo.shares > 0) {
			_accountInfo.unclaimedReward += _accountInfo.shares * accRewardPerShare / 1e18 - _accountInfo.rewardDebt;
		}
		if (_shares > 0) {
			_accountInfo.shares += uint256(_shares);
		}
		else
		if (_shares < 0) {
			_accountInfo.shares -= uint256(-_shares);
		}
		_accountInfo.rewardDebt = _accountInfo.shares * accRewardPerShare / 1e18;
	}

	function _calcSharesFromAmount(uint256 _totalReserve, uint256 _totalSupply, uint256 _amount) internal pure virtual returns (uint256 _shares)
	{
		if (_totalReserve == 0) return _amount;
		return _amount * _totalSupply / _totalReserve;
	}

	function _calcAmountFromShares(uint256 _totalReserve, uint256 _totalSupply, uint256 _shares) internal pure virtual returns (uint256 _amount)
	{
		if (_totalSupply == 0) return _totalReserve;
		return _shares * _totalReserve / _totalSupply;
	}

	function _claimRewards() internal
	{
		uint256 _totalSupply = totalSupply();
		if (_totalSupply > 0) {
			Bitcorn(token).claim();
			uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this)) - totalReward;
			if (_rewardAmount > 0) {
				totalReward += _rewardAmount;
				accRewardPerShare += _rewardAmount * 1e18 / _totalSupply;
			}
		}
	}

	event Deposit(address indexed _account, uint256 _shares);
	event Withdraw(address indexed _account, uint256 _shares);
	event Claim(address indexed _account, uint256 _rewardToken);
}