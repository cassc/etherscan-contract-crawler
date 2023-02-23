// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { LevelXToken } from "./LevelXToken.sol";
import { IMasterChef } from "./IMasterChef.sol";

contract LevelXRewardsModule
{
	using SafeERC20 for IERC20;

	address payable public immutable token; // LVLX
	address public immutable masterChef;
	mapping(address => uint256) public rewardPid;

	constructor(address payable _token, address _masterChef, uint256[] memory _rewardPid)
	{
		token = _token;
		masterChef = _masterChef;
		for (uint256 _i = 0; _i < _rewardPid.length; _i++) {
			address _rewardToken = LevelXToken(_token).rewardIndex(_i + 1);
			rewardPid[_rewardToken] = _rewardPid[_i];
		}
	}

	function claimAll() external returns (uint256[] memory _amounts)
	{
		uint256 _length = LevelXToken(token).rewardIndexLength();
		_amounts = new uint256[](_length);
		for (uint256 _i = 0; _i < _length; _i++) {
			_amounts[_i] = _claim(msg.sender, _i, msg.sender);
		}
		return _amounts;
	}

	function compoundAll() external returns (uint256[] memory _amounts)
	{
		uint256 _length = LevelXToken(token).rewardIndexLength();
		_amounts = new uint256[](_length);
		_amounts[0] = _claim(msg.sender, 0, msg.sender);
		for (uint256 _i = 1; _i < _length; _i++) {
			_amounts[_i] = _compound(msg.sender, _i, msg.sender);
		}
		return _amounts;
	}

	function claim(uint256 _i) external returns (uint256 _amount)
	{
		return _claim(msg.sender, _i, msg.sender);
	}

	function compound(uint256 _i) external returns (uint256 _amount)
	{
		if (_i == 0) {
			return _claim(msg.sender, _i, msg.sender);
		} else {
			return _compound(msg.sender, _i, msg.sender);
		}
	}

	function _claim(address _account, uint256 _i, address _receiver) internal returns (uint256 _amount)
	{
		return LevelXToken(token).claimOnBehalfOf(_account, _i, _receiver);
	}

	function _compound(address _account, uint256 _i, address _receiver) internal returns (uint256 _amount)
	{
		_amount = _claim(_account, _i, address(this));
		address _rewardToken = LevelXToken(token).rewardIndex(_i);
		uint256 _rewardPid = rewardPid[_rewardToken];
		IERC20(_rewardToken).safeApprove(masterChef, _amount);
		IMasterChef(masterChef).depositOnBehalfOf(_rewardPid, _amount, _receiver, address(0));
		return _amount;
	}
}