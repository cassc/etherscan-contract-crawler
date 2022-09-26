//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./Dependencies/CheckContract.sol";
import "./Dependencies/Initializable.sol";

import "./Interfaces/IStabilityPoolManager.sol";
import "./Interfaces/IDfrancParameters.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/ICommunityIssuance.sol";

contract AdminContract is Ownable, Initializable {
	string public constant NAME = "AdminContract";

	bytes32 public constant STABILITY_POOL_NAME_BYTES =
		0xf704b47f65a99b2219b7213612db4be4a436cdf50624f4baca1373ef0de0aac7;
	bool public isInitialized;

	IDfrancParameters private dfrancParameters;
	IStabilityPoolManager private stabilityPoolManager;
	ICommunityIssuance private communityIssuance;

	address borrowerOperationsAddress;
	address troveManagerAddress;
	address troveManagerHelpersAddress;
	address dchfTokenAddress;
	address sortedTrovesAddress;

	function setAddresses(
		address _paramaters,
		address _stabilityPoolManager,
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _dchfTokenAddress,
		address _sortedTrovesAddress,
		address _communityIssuanceAddress
	) external initializer onlyOwner {
		require(!isInitialized, "Already initialized");
		CheckContract(_paramaters);
		CheckContract(_stabilityPoolManager);
		CheckContract(_borrowerOperationsAddress);
		CheckContract(_troveManagerAddress);
		CheckContract(_troveManagerHelpersAddress);
		CheckContract(_dchfTokenAddress);
		CheckContract(_sortedTrovesAddress);
		CheckContract(_communityIssuanceAddress);
		isInitialized = true;

		borrowerOperationsAddress = _borrowerOperationsAddress;
		troveManagerAddress = _troveManagerAddress;
		troveManagerHelpersAddress = _troveManagerHelpersAddress;
		dchfTokenAddress = _dchfTokenAddress;
		sortedTrovesAddress = _sortedTrovesAddress;
		communityIssuance = ICommunityIssuance(_communityIssuanceAddress);

		dfrancParameters = IDfrancParameters(_paramaters);
		stabilityPoolManager = IStabilityPoolManager(_stabilityPoolManager);
	}

	//Needs to approve Community Issuance to use this fonction.
	function addNewCollateral(
		address _stabilityPoolProxyAddress,
		address _chainlinkOracle,
		address _chainlinkIndex,
		uint256 assignedToken,
		uint256 _tokenPerWeekDistributed,
		uint256 redemptionLockInDay
	) external onlyOwner {
		address _asset = IStabilityPool(_stabilityPoolProxyAddress).getAssetType();

		require(
			stabilityPoolManager.unsafeGetAssetStabilityPool(_asset) == address(0),
			"This collateral already exists"
		);

		dfrancParameters.priceFeed().addOracle(_asset, _chainlinkOracle, _chainlinkIndex);
		dfrancParameters.setAsDefaultWithRemptionBlock(_asset, redemptionLockInDay);

		stabilityPoolManager.addStabilityPool(_asset, _stabilityPoolProxyAddress);
		communityIssuance.addFundToStabilityPoolFrom(
			_stabilityPoolProxyAddress,
			assignedToken,
			msg.sender
		);
		communityIssuance.setWeeklyDfrancDistribution(
			_stabilityPoolProxyAddress,
			_tokenPerWeekDistributed
		);
	}
}