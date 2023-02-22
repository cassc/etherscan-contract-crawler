// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniswapV2Router } from "./IUniswapV2Router.sol";
import { LevelXToken } from "./LevelXToken.sol";

contract LevelXReferralPool is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		bool exists; // indexing flag
		uint64 epoch; // last interaction epoch
		uint256 amount; // sales volume for the epoch
		uint256 reward; // accumulated claimable reward
		uint256 reserved0;
		uint256 reserved1;
		uint256 reserved2;
	}

	struct EpochInfo {
		uint256 amount; // sales volume for the epoch
		uint256 reward; // reward distributed for the epoch
		uint256 reserved0;
		uint256 reserved1;
		uint256 reserved2;
	}

	address public salesToken; // LVLX
	address public rewardToken; // LVLX

	address public router; // PCS router

	uint256 public totalReward = 0;
	uint256 public pendingReward = 0;
	mapping(uint64 => EpochInfo) public epochInfo;

	uint64 public epochLength = 1 weeks;
	uint64 public epoch = uint64(block.timestamp);
	uint64 public nextEpoch = (epoch / epochLength + 1) * epochLength; // Thu 00:00:00 GMT

	uint256 public dripPerEpoch = 10e16; // 10%

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	constructor(address payable _salesToken, address _rewardToken, address _router)
	{
		initialize(msg.sender, _salesToken, _rewardToken, _router);
	}

	function initialize(address _owner, address payable _salesToken, address _rewardToken, address _router) public initializer
	{
		_transferOwnership(_owner);

		totalReward = 0;
		pendingReward = 0;

		epochLength = 1 weeks;
		epoch = uint64(block.timestamp);
		nextEpoch = (epoch / epochLength + 1) * epochLength; // Thu 00:00:00 GMT

		dripPerEpoch = 10e16; // 10%

		salesToken = _salesToken;
		rewardToken = _rewardToken;
		router = _router;
	}

	function updateEpochLength(uint64 _epochLength) external onlyOwner
	{
		require(_epochLength > 0, "invalid length");
		epochLength = _epochLength;
	}

	function updateNextEpoch(uint64 _nextEpoch) external onlyOwner
	{
		require(_nextEpoch > block.timestamp, "invalid epoch");
		nextEpoch = _nextEpoch;
	}

	function updateDripPerEpoch(uint256 _dripPerEpoch) external onlyOwner
	{
		require(_dripPerEpoch <= 100e16, "invalid rate");
		dripPerEpoch = _dripPerEpoch;
	}

	function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline, address _referral) external payable nonReentrant returns (uint256 _amountOut)
	{
		address _tokenOut = _path[_path.length - 1];
		require(_tokenOut == salesToken, "invalid token");

		uint256 _balanceOut = LevelXToken(payable(_tokenOut)).computeBalanceOf(_to);

		IUniswapV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(_amountOutMin, _path, _to, _deadline);

		_amountOut = LevelXToken(payable(_tokenOut)).computeBalanceOf(_to) - _balanceOut;

		_updateEpoch();

		_updateAccount(_referral, _amountOut);

		emit Referral(address(0), _tokenOut, msg.value, _amountOut, _referral);

		return _amountOut;
	}

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 _amountIn, uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline, address _referral) external nonReentrant returns (uint256 _amountOut)
	{
		address _tokenIn = _path[0];
		address _tokenOut = _path[_path.length - 1];
		require(_tokenOut == salesToken, "invalid token");

		uint256 _balanceOut = LevelXToken(payable(_tokenOut)).computeBalanceOf(_to);

		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
		uint256 _balanceIn = IERC20(_tokenIn).balanceOf(address(this));

		IERC20(_tokenIn).safeApprove(router, _balanceIn);
		IUniswapV2Router(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(_balanceIn, _amountOutMin, _path, _to, _deadline);

		_amountOut = LevelXToken(payable(_tokenOut)).computeBalanceOf(_to) - _balanceOut;

		emit Referral(_tokenIn, _tokenOut, _amountIn, _amountOut, _referral);

		_updateEpoch();

		_updateAccount(_referral, _amountOut);

		return _amountOut;
	}

	function estimateNextEpochReward(address _account) external view returns (uint256 _rewardAmount)
	{
		EpochInfo storage _epochInfo = epochInfo[epoch];
		if (_epochInfo.amount > 0) {
			uint256 _reward = pendingReward * dripPerEpoch / 100e16;
			return accountInfo[_account].amount * _reward / _epochInfo.amount;
		}
		return 0;
	}

	function claim() external nonReentrant returns (uint256 _rewardAmount)
	{
		_updateEpoch();

		_updateAccount(msg.sender, 0);

		AccountInfo storage _accountInfo = accountInfo[msg.sender];

		_rewardAmount = _accountInfo.reward;

		if (_rewardAmount > 0) {
			_accountInfo.reward = 0;

			totalReward -= _rewardAmount;

			IERC20(rewardToken).safeTransfer(msg.sender, _rewardAmount);
		}

		emit Claim(msg.sender, rewardToken, _rewardAmount);

		return _rewardAmount;
	}

	function reward(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateEpoch();

		pendingReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit Reward(msg.sender, rewardToken, _amount);
	}

	function updateEpoch() external
	{
		_updateEpoch();
	}

	function _updateEpoch() internal
	{
		if (block.timestamp < nextEpoch) return;

		EpochInfo storage _epochInfo = epochInfo[epoch];

		if (_epochInfo.amount > 0) {
			uint256 _reward = pendingReward * dripPerEpoch / 100e16;

			_epochInfo.reward = _reward;

			totalReward += _reward;

			pendingReward -= _reward;
		}

		do {
			epoch = nextEpoch;
			nextEpoch += epochLength;
		} while (nextEpoch <= block.timestamp);
	}

	function _updateAccount(address _account, uint256 _amount) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			_accountInfo.epoch = epoch;
			accountIndex.push(_account);
		}

		if (_accountInfo.epoch == epoch) {
			_accountInfo.amount += _amount;
		} else {
			EpochInfo storage _epochInfo = epochInfo[_accountInfo.epoch];
			_accountInfo.reward += _accountInfo.amount * _epochInfo.reward / _epochInfo.amount;
			_accountInfo.epoch = epoch;
			_accountInfo.amount = _amount;
		}

		epochInfo[epoch].amount += _amount;
	}

	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Referral(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut, address indexed _referral);
}