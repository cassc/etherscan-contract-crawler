// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
	function exit(bool claimRewards) external;

	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

	function rdntToken() external view returns (IMintableToken);

	function getPriceProvider() external view returns (address);

	function lockInfo(address user) external view returns (LockedBalance[] memory);

	function autocompoundEnabled(address user) external view returns (bool);

	function defaultLockIndex(address _user) external view returns (uint256);

	function autoRelockDisabled(address user) external view returns (bool);

	function totalBalance(address user) external view returns (uint256);

	function lockedBalance(address user) external view returns (uint256);

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);

	function getBalances(address _user) external view returns (Balances memory);

	function zapVestingToLp(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function userSlippage(address) external view returns (uint256);

	function claimFromConverter(address) external;

	function vestTokens(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 bountyAmt);

	function setAutocompound(bool _newVal) external;

	function setUserSlippage(uint256 slippage) external;

	function toggleAutocompound() external;

	function getAutocompoundEnabled(address _user) external view returns (bool);
}