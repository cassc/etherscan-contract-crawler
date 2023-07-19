// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";

interface IAdminContract {
	// Structs ----------------------------------------------------------------------------------------------------------

	struct CollateralParams {
		uint256 decimals;
		uint256 index; // Maps to token address in validCollateral[]
		bool active;
		uint256 borrowingFee;
		uint256 ccr;
		uint256 mcr;
		uint256 debtTokenGasCompensation; // Amount of debtToken to be locked in gas pool on opening vessels
		uint256 minNetDebt; // Minimum amount of net debtToken a vessel must have
		uint256 mintCap;
		uint256 percentDivisor;
		uint256 redemptionFeeFloor;
		uint256 redemptionBlockTimestamp;
	}

	// Custom Errors ----------------------------------------------------------------------------------------------------

	error SafeCheckError(string parameter, uint256 valueEntered, uint256 minValue, uint256 maxValue);
	error AdminContract__OnlyOwner();
	error AdminContract__OnlyTimelock();
	error AdminContract__CollateralAlreadyInitialized();

	// Events -----------------------------------------------------------------------------------------------------------

	event CollateralAdded(address _collateral);
	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeChanged(uint256 oldBorrowingFee, uint256 newBorrowingFee);
	event RedemptionFeeFloorChanged(uint256 oldRedemptionFeeFloor, uint256 newRedemptionFeeFloor);
	event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);
	event RedemptionBlockTimestampChanged(address _collateral, uint256 _blockTimestamp);

	// Functions --------------------------------------------------------------------------------------------------------

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	function addNewCollateral(address _collateral, uint256 _debtTokenGasCompensation, uint256 _decimals) external;

	function setCollateralParameters(
		address _collateral,
		uint256 borrowingFee,
		uint256 ccr,
		uint256 mcr,
		uint256 minNetDebt,
		uint256 mintCap,
		uint256 percentDivisor,
		uint256 redemptionFeeFloor
	) external;

	function setMCR(address _collateral, uint256 newMCR) external;

	function setCCR(address _collateral, uint256 newCCR) external;

	function setMinNetDebt(address _collateral, uint256 minNetDebt) external;

	function setPercentDivisor(address _collateral, uint256 precentDivisor) external;

	function setBorrowingFee(address _collateral, uint256 borrowingFee) external;

	function setRedemptionFeeFloor(address _collateral, uint256 redemptionFeeFloor) external;

	function setMintCap(address _collateral, uint256 mintCap) external;

	function setRedemptionBlockTimestamp(address _collateral, uint256 _blockTimestamp) external;

	function getIndex(address _collateral) external view returns (uint256);

	function getIsActive(address _collateral) external view returns (bool);

	function getValidCollateral() external view returns (address[] memory);

	function getMcr(address _collateral) external view returns (uint256);

	function getCcr(address _collateral) external view returns (uint256);

	function getDebtTokenGasCompensation(address _collateral) external view returns (uint256);

	function getMinNetDebt(address _collateral) external view returns (uint256);

	function getPercentDivisor(address _collateral) external view returns (uint256);

	function getBorrowingFee(address _collateral) external view returns (uint256);

	function getRedemptionFeeFloor(address _collateral) external view returns (uint256);

	function getRedemptionBlockTimestamp(address _collateral) external view returns (uint256);

	function getMintCap(address _collateral) external view returns (uint256);

	function getTotalAssetDebt(address _asset) external view returns (uint256);
}