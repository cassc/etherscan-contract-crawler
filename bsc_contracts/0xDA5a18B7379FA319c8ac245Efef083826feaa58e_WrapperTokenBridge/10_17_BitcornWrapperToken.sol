// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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

	address constant WRAPPER_TOKEN_BRIDGE = 0x0DC52B853030E587eb10b11cfF7d5FDdFA594E71;

	address public token;
	address public rewardToken;

	uint256 public totalReward = 0;
	uint256 public accRewardPerShare = 0;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	constructor(address _token)
		ERC20("", "")
	{
		initialize(_token);
	}

	function name() public pure override returns (string memory _name)
	{
		return "Bitcorn Wrapper Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "BWT";
	}

	function initialize(address _token) public initializer
	{
		totalReward = 0;
		accRewardPerShare = 0;

		token = _token;
		rewardToken = Bitcorn(_token).rewardToken();
	}

	function migrate(address[] memory _accounts, uint256[] memory _shares) external
	{
		require(rewardToken == address(0), "illegal state");
		rewardToken = Bitcorn(token).rewardToken();
		uint256 _totalShares = 0;
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];
			if (!_accountInfo.exists) {
				_accountInfo.exists = true;
				accountIndex.push(_account);
			}
			_accountInfo.shares = _shares[_i];
			_totalShares += _shares[_i];
		}
		require(_totalShares == totalSupply(), "missing shares");
	}

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
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}
		_claimRewards();
		if (_accountInfo.shares > 0) {
			_accountInfo.unclaimedReward += _accountInfo.shares * accRewardPerShare / 1e18 - _accountInfo.rewardDebt;
		}
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			uint256 _newTotalReserve = totalReserve();
			_amount = _newTotalReserve - _totalReserve;
			_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
			_mint(msg.sender, _shares);
		}
		_accountInfo.shares += _shares;
		_accountInfo.rewardDebt = _accountInfo.shares * accRewardPerShare / 1e18;
		emit Deposit(_account, _shares);
		return _shares;
	}

	function withdraw(uint256 _shares) external returns (uint256 _amount)
	{
		return withdraw(_shares, msg.sender);
	}

	function withdraw(uint256 _shares, address _account) public nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		AccountInfo storage _accountInfo = accountInfo[_account];
		require(_accountInfo.exists, "unknown account");
		require(_shares <= _accountInfo.shares, "insufficient balance");
		_claimRewards();
		if (_accountInfo.shares > 0) {
			_accountInfo.unclaimedReward += _accountInfo.shares * accRewardPerShare / 1e18 - _accountInfo.rewardDebt;
		}
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			_amount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
			_burn(msg.sender, _shares);
			IERC20(token).safeTransfer(msg.sender, _amount);
		}
		_accountInfo.shares -= _shares;
		_accountInfo.rewardDebt = _accountInfo.shares * accRewardPerShare / 1e18;
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
		AccountInfo storage _accountInfo = accountInfo[_account];
		require(_accountInfo.exists, "unknown account");
		_claimRewards();
		if (_accountInfo.shares > 0) {
			_accountInfo.unclaimedReward += _accountInfo.shares * accRewardPerShare / 1e18 - _accountInfo.rewardDebt;
		}
		_accountInfo.rewardDebt = _accountInfo.shares * accRewardPerShare / 1e18;
		_rewardAmount = _accountInfo.unclaimedReward;
		_accountInfo.unclaimedReward = 0;
		if (_rewardAmount > 0) {
			totalReward -= _rewardAmount;
			IERC20(rewardToken).safeTransfer(_account, _rewardAmount);
		}
		emit Claim(_account, _rewardAmount);
		return _rewardAmount;
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
				accRewardPerShare += _rewardAmount / _totalSupply;
			}
		}
	}

	event Deposit(address indexed _account, uint256 _shares);
	event Withdraw(address indexed _account, uint256 _shares);
	event Claim(address indexed _account, uint256 _rewardToken);
}