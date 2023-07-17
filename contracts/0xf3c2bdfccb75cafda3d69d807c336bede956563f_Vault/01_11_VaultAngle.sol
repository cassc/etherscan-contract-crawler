//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./interfaces/IMultiRewards.sol";
import "./interfaces/IAngle.sol";

interface IController {
	function withdraw(address, uint256) external;

	function balanceOf(address) external view returns (uint256);

	function earn(address, uint256) external;

	function want(address) external view returns (address);

	function rewards() external view returns (address);

	function vaults(address) external view returns (address);

	function strategies(address) external view returns (address);
}

interface IStrategy {
	function stake() external;
}

contract Vault is ERC20 {
	using SafeERC20 for IERC20;
	using Address for address;

	IERC20 public token;

	address public sanUSDC_EUR = 0x9C215206Da4bf108aE5aEEf9dA7caD3352A36Dad;
	address public staking = 0x2Fa1255383364F6e17Be6A6aC7A56C9aCD6850a3;
	address public stableMaster = 0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87;
	address public poolManager = 0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD;
	address public governance;
	address public controller;
	address public gauge;

	constructor(address _token, address _controller) ERC20("Stake DAO Angle USDC strat", "sdsanUSDC_EUR") {
		token = IERC20(_token);
		governance = msg.sender;
		controller = _controller;
	}

	function deposit(uint256 _amount) public {
		require(gauge != address(0), "Gauge not yet initialized");
		token.safeTransferFrom(msg.sender, address(this), _amount);
		// rate 1:1 with san LP minted
		uint256 shares = _earn();
		_mint(address(this), shares);
		IERC20(address(this)).approve(gauge, shares);
		IMultiRewards(gauge).stakeFor(msg.sender, shares);
	}

	function depositAll() external {
		deposit(token.balanceOf(msg.sender));
	}

	function _earn() internal returns (uint256) {
		uint256 _bal = token.balanceOf(address(this));
		uint256 stakedBefore = IERC20(sanUSDC_EUR).balanceOf(address(this));
		token.safeTransfer(controller, _bal);
		IController(controller).earn(address(token), _bal);
		uint256 stakedAfter = IERC20(sanUSDC_EUR).balanceOf(address(this));
		return stakedAfter - stakedBefore;
	}

	function withdraw(uint256 _shares) public {
		uint256 userTotalShares = IMultiRewards(gauge).balanceOf(msg.sender);
		require(_shares <= userTotalShares, "Not enough staked");
		IMultiRewards(gauge).withdrawFor(msg.sender, _shares);
		_burn(address(this), _shares);
		uint256 sanUsdcEurBal = IERC20(sanUSDC_EUR).balanceOf(address(this));
		if (_shares > sanUsdcEurBal) {
			IController(controller).withdraw(address(token), _shares);
		} else {
			IStableMaster(stableMaster).withdraw(_shares, address(this), address(this), IPoolManager(poolManager));
		}
		uint256 usdcAmount = IERC20(token).balanceOf(address(this));

		token.safeTransfer(msg.sender, usdcAmount);
	}

	function withdrawAll() external {
		withdraw(balanceOf(msg.sender));
	}

	// Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
	function harvest(address reserve, uint256 amount) external {
		require(msg.sender == controller, "!controller");
		require(reserve != address(token), "token");
		IERC20(reserve).safeTransfer(controller, amount);
	}

	function getPricePerFullShare() public pure returns (uint256) {
		return 1e6;
	}

	function balance() public view returns (uint256) {
		return IController(controller).balanceOf(address(token));
	}

	function setGovernance(address _governance) public {
		require(msg.sender == governance, "!governance");
		governance = _governance;
	}

	function setController(address _controller) public {
		require(msg.sender == governance, "!governance");
		controller = _controller;
	}

	function setGauge(address _gauge) public {
		require(msg.sender == governance, "!governance");
		gauge = _gauge;
	}

	function decimals() public view override returns (uint8) {
		return 6;
	}

	function earn() external {
		require(msg.sender == governance, "!governance");
		address strategy = IController(controller).strategies(address(token));
		uint256 _bal = IERC20(sanUSDC_EUR).balanceOf(address(this));
		IERC20(sanUSDC_EUR).safeTransfer(strategy, _bal);
		IStrategy(strategy).stake();
	}

	function withdrawRescue() external {
		uint256 userTotalShares = IMultiRewards(gauge).balanceOf(msg.sender);
		IMultiRewards(gauge).withdrawFor(msg.sender, userTotalShares);
		_burn(address(this), userTotalShares);
		IERC20(sanUSDC_EUR).transfer(msg.sender, userTotalShares);
	}
}