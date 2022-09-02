// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./EternalStorage.sol";
import "./MembershipsTypes.sol";

contract MembershipsView is MembershipsTypes {
	EternalStorage private _eternalStorage;

	constructor(address eternalStorage) {
		_eternalStorage = EternalStorage(eternalStorage);
	}

	function getCampaignsLength() external view returns (uint256) {
		return _eternalStorage.getCampaignsLength();
	}

	function getCampaign(uint256 index)
		external
		view
		returns (Campaign memory)
	{
		return _eternalStorage.getCampaign(index);
	}

	function getCampaignBySchedule(bytes32 schedule)
		external
		view
		returns (ScheduleCampaign memory)
	{
		(
			bytes32 campaignId,
			uint256 campaignIndex,
			uint256 scheduleIndex
		) = _eternalStorage.scheduleToCampaign(schedule);
		return ScheduleCampaign(campaignId, campaignIndex, scheduleIndex);
	}

	function getCampaignByOwner(address owner)
		external
		view
		returns (uint256, Campaign[] memory)
	{
		uint256 campaignsByOwnerLength = _eternalStorage
			.getCampaignByAddressLength(owner);
		Campaign[] memory campaigns = new Campaign[](campaignsByOwnerLength);

		uint256 length = 0;
		for (uint256 i = 0; i < campaignsByOwnerLength; i++) {
			(
				uint256 campaignIndex,
				MembershipsTypes.UserType userType
			) = _eternalStorage.campaignsByAddress(owner, i);
			if (userType == MembershipsTypes.UserType.OWNER) {
				Campaign memory c = _eternalStorage.getCampaign(campaignIndex);
				campaigns[length++] = c;
			}
		}
		return (length, campaigns);
	}

	function getCampaignByReferral(address referral)
		external
		view
		returns (uint256, Campaign[] memory)
	{
		uint256 campaignsByAddressLength = _eternalStorage
			.getCampaignByAddressLength(referral);
		Campaign[] memory campaigns = new Campaign[](campaignsByAddressLength);

		uint256 length = 0;
		for (uint256 i = 0; i < campaignsByAddressLength; i++) {
			(
				uint256 campaignIndex,
				MembershipsTypes.UserType userType
			) = _eternalStorage.campaignsByAddress(referral, i);
			if (userType == MembershipsTypes.UserType.REFERRAL) {
				Campaign memory c = _eternalStorage.getCampaign(campaignIndex);
				campaigns[length++] = c;
			}
		}
		return (length, campaigns);
	}

	function getSchedule(bytes32 scheduleId)
		external
		view
		returns (MintingSchedule memory)
	{
		return _eternalStorage.getSchedule(scheduleId);
	}

	function getReferral(bytes32 record)
		external
		view
		returns (ScheduleReferral memory)
	{
		return _eternalStorage.getReferral(record);
	}

	function getBuyWalletCount(bytes32 record) external view returns (uint256) {
		return _eternalStorage.getBuyWalletCount(record);
	}

	function getClaimed(bytes32 scheduleID, UserType userType)
		external
		view
		returns (uint256)
	{
		return _eternalStorage.getClaimed(scheduleID, userType);
	}

	function getBuyPerWallet(bytes32 scheduleId, address addr)
		public
		view
		returns (uint256)
	{
		return _eternalStorage.getBuyPerWallet(scheduleId, addr);
	}

	function getTokensAllowed() public view returns (address[] memory) {
		return _eternalStorage.getTokensAllowed();
	}

	function getCampaignMetadata(bytes32 campaignId)
		public
		view
		returns (string memory)
	{
		return _eternalStorage.getCampaignMetadata(campaignId);
	}
}