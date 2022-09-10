// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { MasterChef } from "./MasterChef.sol";

interface IWrapperToken
{
	function token() external view returns (address _token);

	function wrap(uint256 _amount) external;
	function unwrap(uint256 _amount) external;
}

contract WrapperTokenBridge is Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	address public immutable masterChef;

	constructor(address _masterChef)
	{
		masterChef = _masterChef;
	}

	function deposit(uint256 _pid, uint256 _amount) external nonReentrant
	{
		(address _wtoken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
		address _token = IWrapperToken(_wtoken).token();
		IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
		IERC20(_token).safeApprove(_wtoken, _amount);
		IWrapperToken(_wtoken).wrap(_amount);
		IERC20(_wtoken).safeApprove(masterChef, _amount);
		MasterChef(masterChef).depositOnBehalfOf(_pid, _amount, msg.sender);
	}

	function withdraw(uint256 _pid, uint256 _amount) external nonReentrant
	{
		(address _wtoken,,,,,,,) = MasterChef(masterChef).poolInfo(_pid);
		address _token = IWrapperToken(_wtoken).token();
		MasterChef(masterChef).withdrawOnBehalfOf(_pid, _amount, msg.sender);
		IWrapperToken(_wtoken).unwrap(_amount);
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}
}