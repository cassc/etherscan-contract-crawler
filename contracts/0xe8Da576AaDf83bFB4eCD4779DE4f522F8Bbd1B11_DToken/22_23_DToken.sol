// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ERC20Base} from "./ERC20Base.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {IPolemarch} from "../../interfaces/IPolemarch.sol";
import {IDToken} from "../../interfaces/IDToken.sol";

contract DToken is ERC20Base, IDToken {
	using WadRayMath for uint256;
	using SafeCast for uint256;

	address internal _exchequerSafe;
	address internal _underlyingAsset;
	// Map of users and their last update timestamp (address user => lastUpdateTimestamp)
	mapping(address => uint40) internal _timestamps;
	uint128 internal _averageRate;
	uint40 internal _totalSupplyTimestamp;
	// borrow balance needs to be in place to check if a principal balance is over borrowMax for LoC
	// mapping(address => uint256) internal _borrowBalances;

	function initialize(
		IPolemarch polemarch,
		string memory name,
		string memory symbol,
		uint8 decimals,
		address exchequerSafe,
		address underlyingAsset
	) external initializer {
		ERC20Base.initialize(polemarch, name, symbol, decimals);
		_exchequerSafe = exchequerSafe;
		_underlyingAsset = underlyingAsset;
		// emit Initialized(underlyingAsset, decimals);
	}

	function balanceOf(address user) 
		public 
		view 
		virtual 
		override(IERC20Upgradeable, ERC20Upgradeable)
		returns (uint256) 
	{
		uint256 userBalance = super.balanceOf(user);
		uint256 rate = _additionalUserData[user];
		// rate = rate.wadToRay();
		if (userBalance == 0) {
			return 0;
		}
		uint256 cumulatedInterest = MathUtils.calculateLinearInterest(
			rate,
			_timestamps[user]
		);
		return userBalance.rayMul(cumulatedInterest);
	}

	function mint(address user, uint256 amount) external virtual onlyPolemarch {
		(uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(user);
		uint256 previousSupply = totalSupply();
		uint256 currentAverageRate = _averageRate;
		uint256 nextSupply = _totalSupply = previousSupply + amount;
		uint256 amountInRay = amount.wadToRay();
		uint256 rate = uint256(_additionalUserData[user]);
		currentAverageRate = _averageRate = ((currentAverageRate.rayMul(previousSupply.wadToRay()) + 
			rate.rayMul(amountInRay)).rayDiv(nextSupply.wadToRay())).toUint128();

		_totalSupplyTimestamp = _timestamps[user] = uint40(block.timestamp);
		uint amountToMint = amount + balanceIncrease;
		// _borrowBalances[user] += amount;
		_mint(user, amountToMint);
		emit Mint(user, currentBalance, balanceIncrease, amount);
	}

	function burn(address user, uint256 amount) external virtual onlyPolemarch {
		(uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(user);
		uint256 previousSupply = totalSupply();
		uint256 nextAverageRate = 0;
		uint256 nextSupply = 0;
		uint256 rate = uint256(_additionalUserData[user]);

		if (previousSupply <= amount) {
			_averageRate = 0;
			_totalSupply = 0;
		} else {
			nextSupply = _totalSupply = previousSupply + amount;
			uint256 termOne = uint256(_averageRate).rayMul(previousSupply.wadToRay());
			uint256 termTwo = rate.rayMul(amount.wadToRay());

			if (termTwo >= termOne) {
				nextSupply = _totalSupply = _averageRate = 0;
			} else {
				nextAverageRate = _averageRate = ((termOne - termTwo).rayDiv(nextSupply.wadToRay())).toUint128();
			}
		}

		_totalSupplyTimestamp = _timestamps[user] = uint40(block.timestamp);
		if (balanceIncrease > amount) {
			uint256 amountToMint = balanceIncrease - amount;
			_mint(user, amountToMint);
			emit Mint(user, currentBalance, balanceIncrease, amountToMint);
		} else {
			uint256 amountToBurn = amount - balanceIncrease;
			_burn(user, amountToBurn);
			emit Burn(user, currentBalance, balanceIncrease, amountToBurn);
		}
	}

	function totalSupply() 
		public 
		view 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable) 
		returns (uint256) 
	{
		return _calcTotalSupply(_averageRate);
	}

	// updateRate function can be used at the creation and close of line of credit
	function updateRate(address user, uint128 rate) external virtual onlyPolemarch {
		uint256 newRate = uint256(rate).wadToRay();
		_additionalUserData[user] = uint128(newRate);
	}

	function userRate(address user) public view returns (uint128) {
		return _additionalUserData[user];
	}

	function getAverageRate() public view returns (uint256) {
		return uint256(_averageRate);
	}

	// function borrowBalance(address user) public view returns (uint256) {
	// 	return _borrowBalances[user];
	// }

	function _calculateBalanceIncrease(address user) internal view returns (uint256, uint256) {
		uint256 previousBalance = super.balanceOf(user);
		if (previousBalance == 0) {
			return (0, 0);
		}
		uint256 newBalance = balanceOf(user);
		return (previousBalance, newBalance - previousBalance);
	}

	function _calcTotalSupply(uint256 averageRate) internal view returns (uint256) {
		uint256 principalSupply = super.totalSupply();

		if (principalSupply == 0) {
			return 0;
		}

		uint256 cumulatedInterest = MathUtils.calculateLinearInterest(
			averageRate,
			_totalSupplyTimestamp
		);

		return principalSupply.rayMul(cumulatedInterest);
	}

	function transfer(address, uint256) 
		public 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable)
		returns (bool) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}

	function allowance(address, address) 
		public 
		view 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable) 
		returns (uint256) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}

	function approve(address, uint256) 
		public 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable)
		returns (bool) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}

	function transferFrom(address, address, uint256) 
		public 
		virtual 
		override(ERC20Upgradeable, IERC20Upgradeable) 
		returns (bool) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}

	function increaseAllowance(address, uint256) 
		public 
		virtual 
		override(ERC20Upgradeable) 
		returns (bool) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}

	function decreaseAllowance(address, uint256) 
		public 
		virtual 
		override(ERC20Upgradeable) 
		returns (bool) 
	{
		revert("OPERATION_NOT_SUPPORTED");
	}
}