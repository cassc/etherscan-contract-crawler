// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GrowthMigration } from "./GrowthMigration.sol";

contract GrowthPayout is Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	uint256 constant DEFAULT_DAYS_LEFT = 365; // 365 days
	uint256 constant DEFAULT_DAILY_AMOUNT = 275e18; // 275 xGRO

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 8 hours; // UTC+8 (day change at 16h UTC)

	address public immutable token; // xGRO
	address public immutable source;
	address public immutable target;

	uint256 public daysLeft = DEFAULT_DAYS_LEFT;
	uint256 public dailyAmount = DEFAULT_DAILY_AMOUNT;

	uint64 public day = today();

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	constructor(address _token, address _source, address _target)
	{
		token = _token;
		source = _source;
		target = _target;
	}

	function setDaysLeft(uint256 _daysLeft) external onlyOwner
	{
		daysLeft = _daysLeft;
	}

	function setDailyAmount(uint256 _dailyAmount) external onlyOwner
	{
		dailyAmount = _dailyAmount;
	}

	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _dayDiff = _today - day;
		if (_dayDiff > daysLeft) {
			_dayDiff = daysLeft;
		}

		if (_dayDiff > 0) {
			uint256 _amount = dailyAmount * _dayDiff;
			if (_amount > 0) {
				IERC20(token).safeTransferFrom(source, address(this), _amount);
				IERC20(token).safeApprove(target, _amount);
				GrowthMigration(target).donateDrip(_amount);
			}
			daysLeft -= _dayDiff;
		}

		day = _today;
	}
}