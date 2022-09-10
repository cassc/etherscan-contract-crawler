// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMasterChef
{
	function deposit(uint256 _pid, uint256 _amount) external;
	function withdraw(uint256 _pid, uint256 _amount) external;
	function emergencyWithdraw(uint256 _pid) external;
}

contract FarmingWrapperToken is Initializable, Ownable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	address public masterChef;
	uint256 public pid;
	address public token;
	address public rewardToken;

	address public collector;

	bool emergencyMode = false;

	constructor(address _masterChef, uint256 _pid, address _token, address _rewardToken)
		ERC20("", "")
	{
		initialize(msg.sender, _masterChef, _pid, _token, _rewardToken);
	}

	function name() public pure override returns (string memory _name)
	{
		return "Farming Wrapper Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "FWT";
	}

	function initialize(address _owner, address _masterChef, uint256 _pid, address _token, address _rewardToken) public initializer
	{
		_transferOwnership(_owner);

		emergencyMode = false;

		require(_rewardToken != _token, "invalid token");
		masterChef = _masterChef;
		pid = _pid;
		token = _token;
		rewardToken = _rewardToken;
	}

	function declareEmergencyMode() external onlyOwner
	{
		require(!emergencyMode, "unavailable");
		emergencyMode = true;
		IMasterChef(masterChef).emergencyWithdraw(pid);
	}

	function setCollector(address _collector) external onlyOwner
	{
		collector = _collector;
	}

	function wrap(uint256 _amount) external nonReentrant
	{
		_mint(msg.sender, _amount);
		IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
		if (!emergencyMode) {
			IERC20(token).safeApprove(masterChef, _amount);
			IMasterChef(masterChef).deposit(pid, _amount);
		}
	}

	function unwrap(uint256 _amount) external nonReentrant
	{
		_burn(msg.sender, _amount);
		if (!emergencyMode) {
			IMasterChef(masterChef).withdraw(pid, _amount);
		}
		IERC20(token).safeTransfer(msg.sender, _amount);
	}

	function collect() external nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == collector, "access denied");
		IMasterChef(masterChef).withdraw(pid, 0);
		uint256 _balance = IERC20(rewardToken).balanceOf(address(this));
		IERC20(rewardToken).safeTransfer(msg.sender, _balance);
		return _balance;
	}
}