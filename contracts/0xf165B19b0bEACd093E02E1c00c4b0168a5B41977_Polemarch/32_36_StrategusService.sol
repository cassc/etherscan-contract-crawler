// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ISToken} from "../../../interfaces/ISToken.sol";
import {IDToken} from "../../../interfaces/IDToken.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {Types} from "../types/Types.sol";
import {ExchequerService} from "./ExchequerService.sol";

library StrategusService {
	using ExchequerService for Types.Exchequer;
	using WadRayMath for uint256;
	using SafeCast for uint256;
	using AddressUpgradeable for address;

	function guardDeleteExchequer(
		mapping(uint256 => address) storage exchequersList,
		Types.Exchequer storage exchequer,
		address underlyingAsset
	) internal view {
		require(underlyingAsset != address(0), "ZERO_ADDRESS_NOT_VALID");
		require(exchequer.id != 0 || exchequersList[0] == underlyingAsset, "ASSET_NOT_LISTED");
		require(IERC20Upgradeable(exchequer.sTokenAddress).totalSupply() == 0, "STOKEN_SUPPLY_NOT_ZERO");
		require(IERC20Upgradeable(exchequer.gTokenAddress).totalSupply() == 0, "GTOKEN_SUPPLY_NOT_ZERO");
	}

	function guardAddSupply(
		Types.Exchequer storage exchequer,
		uint256 amount
	) internal view {
		require(amount != 0, "INVALID_AMOUNT");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
		require(exchequer.supplyCap == 0 || 
			exchequer.supplyCap >= (ISToken(exchequer.sTokenAddress).scaledTotalSupply().rayMul(
			exchequer.supplyIndex) + amount), 
			"SUPPLY_CAP_EXCEEDED"
		);
	}

	function guardAddGrantSupply(
		Types.Exchequer storage exchequer,
		uint256 amount
	) internal view {
		require(amount != 0, "INVALID_AMOUNT");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
	}

	function guardWithdraw(
		Types.Exchequer storage exchequer,
		uint256 userBalance,
		uint256 withdrawableBalance,
		uint256 amount
	) internal view {
		require(amount != 0, "INVALID_AMOUNT");
		require(userBalance >= amount, "USER_BALANCE_TOO_LOW");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
		require(amount <= withdrawableBalance, "WITHDRAWABLE_BALANCE_TOO_LOW");
		// add logic to see if the withdrawable amount of the exchequer and the user's proportion of
		// the exchequer is large enough for the withdrawal
		// would need to brainstorm some logic for this [different than collateralized lending]
	}

	function guardCreateLineOfCredit(
		Types.Exchequer storage exchequer,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address underlyingAsset,
		address borrower, 
		uint256 borrowMax,
		uint256 protocolBorrowFee
	) internal view {
		require(linesOfCredit[borrower].deliquent == false, "USER_HAS_DELIQUENT_DEBT");
		require(borrowMax != 0, "INVALID_BORROW_MAX");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
		require(exchequer.borrowingEnabled, "BORROWING_NOT_ENABLED");
		// add requirement using debt tokens for the borrow cap
		require(IERC20(underlyingAsset).balanceOf(exchequer.sTokenAddress) >= borrowMax, 
			"NOT_ENOUGH_UNDERLYING_ASSET_BALANCE"
		);
		require(exchequer.totalDebt + borrowMax <= exchequer.borrowCap || exchequer.borrowCap == 0, 
			"EXCHEQUER_MUST_STAY_BELOW_BORROW_CAP"
		);
		uint256 projectedTotalDebt = (exchequer.totalDebt + borrowMax + protocolBorrowFee).wadToRay();
		uint256 projectedCollateralFactor = projectedTotalDebt.rayDiv(
			IERC20(underlyingAsset).balanceOf(exchequer.gTokenAddress).wadToRay()
		);
		require(projectedCollateralFactor < exchequer.collateralFactor, "NOT_ENOUGH_COLLATERAL");
		require(linesOfCredit[borrower].underlyingAsset == address(0), "USER_ALREADY_HAS_BORROW_POSITION");
	}

	function guardBorrow(
		Types.Exchequer storage exchequer,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower, 
		uint256 amount
	) internal view {
		require(amount != 0, "INVALID_AMOUNT");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
		require(exchequer.borrowingEnabled, "BORROWING_NOT_ENABLED");
		require(linesOfCredit[borrower].borrowMax != 0, "USER_DOES_NOT_HAVE_LINE_OF_CREDIT");
		require(linesOfCredit[borrower].deliquent == false, "USER_HAS_DELIQUENT_DEBT");
		require(IDToken(exchequer.dTokenAddress).balanceOf(borrower) + amount <= linesOfCredit[borrower].borrowMax,
			"USER_CANNOT_BORROW_OVER_MAX_LIMIT"
		);
		require(block.timestamp < linesOfCredit[borrower].expirationTimestamp, "LINE_OF_CREDIT_EXPIRED");
	}

	function guardRepay(
		Types.Exchequer storage exchequer,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower, 
		uint256 amount
	) internal view {
		require(amount != 0, "INVALID_AMOUNT");
		require(exchequer.active, "EXCHEQUER_INACTIVE");
		require(linesOfCredit[borrower].borrowMax != 0, "USER_DOES_NOT_HAVE_LINE_OF_CREDIT");
		require(!linesOfCredit[borrower].deliquent, "USER_DEBT_IS_DELIQUENT");
		require(block.timestamp < linesOfCredit[borrower].expirationTimestamp, "LINE_OF_CREDIT_EXPIRED");
	}

	function guardDelinquency(
		Types.Exchequer storage exchequer,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower
	) internal view {
		require(block.timestamp > linesOfCredit[borrower].expirationTimestamp, "LINE_OF_CREDIT_HAS_NOT_EXPIRED");
		require(IDToken(exchequer.dTokenAddress).balanceOf(borrower) > 10**(exchequer.decimals - 3), "USER_DEBT_BALANCE_APPROX_ZERO");
	}

	function guardCloseLineOfCredit(
		Types.Exchequer storage exchequer,
		mapping(address => Types.LineOfCredit) storage linesOfCredit,
		address borrower
	) internal view {
		require(!linesOfCredit[borrower].deliquent, "USER_DEBT_IS_DELIQUENT");
		require(block.timestamp > linesOfCredit[borrower].expirationTimestamp, "LINE_OF_CREDIT_HAS_NOT_EXPIRED");
		require(IDToken(exchequer.dTokenAddress).balanceOf(borrower) < 10**(exchequer.decimals - 3), "USER_DEBT_BALANCE_IS_NOT_ZERO");
	}
}