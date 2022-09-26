// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMONStaking {
	// --- Events --

	event TreasuryAddressChanged(address _treausury);
	event SentToTreasury(address indexed _asset, uint256 _amount);
	event MONTokenAddressSet(address _MONTokenAddress);
	event DCHFTokenAddressSet(address _dchfTokenAddress);
	event TroveManagerAddressSet(address _troveManager);
	event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
	event ActivePoolAddressSet(address _activePoolAddress);

	event StakeChanged(address indexed staker, uint256 newStake);
	event StakingGainsAssetWithdrawn(
		address indexed staker,
		address indexed asset,
		uint256 AssetGain
	);
	event StakingGainsDCHFWithdrawn(address indexed staker, uint256 DCHFGain);
	event F_AssetUpdated(address indexed _asset, uint256 _F_ASSET);
	event F_DCHFUpdated(uint256 _F_DCHF);
	event TotalMONStakedUpdated(uint256 _totalMONStaked);
	event AssetSent(address indexed _asset, address indexed _account, uint256 _amount);
	event StakerSnapshotsUpdated(address _staker, uint256 _F_Asset, uint256 _F_DCHF);

	function monToken() external view returns (IERC20);

	// --- Functions ---

	function setAddresses(
		address _MONTokenAddress,
		address _dchfTokenAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress,
		address _activePoolAddress,
		address _treasury
	) external;

	function stake(uint256 _MONamount) external;

	function unstake(uint256 _MONamount) external;

	function increaseF_Asset(address _asset, uint256 _AssetFee) external;

	function increaseF_DCHF(uint256 _MONFee) external;

	function getPendingAssetGain(address _asset, address _user) external view returns (uint256);

	function getPendingDCHFGain(address _user) external view returns (uint256);
}