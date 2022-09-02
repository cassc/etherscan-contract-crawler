// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./MembershipsTypes.sol";

contract EternalStorage is MembershipsTypes, AccessControl {
	bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

	Campaign[] private campaigns;

	mapping(bytes32 => uint256) private campaignToIndex;

	mapping(bytes32 => ScheduleCampaign) public scheduleToCampaign;

	mapping(address => uint256) private campaignsByAddressLength;

	mapping(address => mapping(uint256 => CampaignsAddress))
		public campaignsByAddress;

	mapping(address => uint256) public campaignsCreatedByAddress;

	mapping(bytes32 => MintingSchedule) public schedules;

	mapping(bytes32 => mapping(UserType => uint256)) private _claimed;

	mapping(bytes32 => mapping(address => uint256)) private _buyPerWallet;

	// No of addresses who have bought per schedule
	mapping(bytes32 => uint256) private _buyPerWalletCount;

	mapping(bytes32 => ScheduleReferral) private schedulesReferral;

	event CampaignCreated(address indexed from, uint256 indexed campaignIndex);

	address[] private tokensAllowedArr;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(WRITER_ROLE, address(this));
	}

	function getSchedule(bytes32 record)
		external
		view
		returns (MintingSchedule memory)
	{
		return schedules[record];
	}

	function setSchedule(bytes32 record, MintingSchedule calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		schedules[record] = value;
	}

	function getReferral(bytes32 record)
		external
		view
		returns (ScheduleReferral memory)
	{
		return schedulesReferral[record];
	}

	function setReferral(bytes32 record, ScheduleReferral calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		schedulesReferral[record] = value;
	}

	function removeReferral(bytes32 record, address oldReferral)
		external
		onlyRole(WRITER_ROLE)
	{
		//@dev: this is to remove indexes to filter campaings by referral
		uint256 campaignsByOwner = campaignsByAddressLength[oldReferral];
		for (uint256 i = 0; i < campaignsByOwner; i++) {
			if (
				campaignsByAddress[oldReferral][i].campaignIndex ==
				scheduleToCampaign[record].campaignIndex
			) {
				campaignsByAddress[oldReferral][i] = campaignsByAddress[
					oldReferral
				][campaignsByOwner - 1];
				delete campaignsByAddress[oldReferral][campaignsByOwner - 1];
				campaignsByAddressLength[oldReferral]--;
				break;
			}
		}
	}

	function setBuyPerWallet(
		bytes32 scheduleID,
		address addr,
		uint256 value
	) external onlyRole(WRITER_ROLE) {
		if (_buyPerWallet[scheduleID][addr] == 0) {
			_buyPerWalletCount[scheduleID]++;
		}
		_buyPerWallet[scheduleID][addr] = value;
	}

	function getBuyPerWallet(bytes32 scheduleID, address addr)
		external
		view
		returns (uint256)
	{
		return _buyPerWallet[scheduleID][addr];
	}

	function setTokensAllowed(address token, bool value)
		external
		onlyRole(WRITER_ROLE)
	{
		for (uint256 i = 0; i < tokensAllowedArr.length; i++) {
			if (tokensAllowedArr[i] == token) {
				if (value) {
					return;
				} else {
					tokensAllowedArr[i] = tokensAllowedArr[
						tokensAllowedArr.length - 1
					];
					tokensAllowedArr.pop();
					return;
				}
			}
		}
		if (value) {
			tokensAllowedArr.push(token);
		}
	}

	function getTokensAllowed() external view returns (address[] memory) {
		return tokensAllowedArr;
	}

	function isTokenAllowed(address addr) external view returns (bool) {
		for (uint256 i = 0; i < tokensAllowedArr.length; i++) {
			if (tokensAllowedArr[i] == addr) {
				return true;
			}
		}
		return false;
	}

	function getBuyWalletCount(bytes32 scheduleID)
		external
		view
		returns (uint256)
	{
		return _buyPerWalletCount[scheduleID];
	}

	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) external onlyRole(WRITER_ROLE) {
		campaigns[campaignToIndex[campaignId]].metadata = metadata;
	}

	function getCampaignMetadata(bytes32 campaignId)
		external
		view
		returns (string memory)
	{
		return campaigns[campaignToIndex[campaignId]].metadata;
	}

	function setClaimed(
		bytes32 scheduleID,
		UserType userType,
		uint256 value
	) external onlyRole(WRITER_ROLE) {
		_claimed[scheduleID][userType] = value;
	}

	function getClaimed(bytes32 scheduleID, UserType userType)
		external
		view
		returns (uint256)
	{
		return _claimed[scheduleID][userType];
	}

	function addCampaign(Campaign calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		bytes32 phase0 = value.phases[0];

		campaigns.push(value);

		for (uint256 i = 0; i < value.phases.length; i++) {
			scheduleToCampaign[value.phases[i]] = ScheduleCampaign(
				value.campaignId,
				campaigns.length - 1,
				i
			);
		}

		//@dev: this is to update indexes to filter campaings by owner
		address owner = schedules[phase0].owner;
		uint256 campaignsByOwner = campaignsByAddressLength[owner];
		campaignsByAddress[owner][campaignsByOwner].campaignIndex =
			campaigns.length -
			1;
		campaignsByAddress[owner][campaignsByOwner].userType = UserType.OWNER;
		campaignsByAddressLength[owner]++;

		//@dev: this is to update indexes to filter campaings by referral
		for (uint256 i = 0; i < value.phases.length; i++) {
			address referral = schedulesReferral[value.phases[i]].referral;
			if (referral != address(0)) {
				this.updateReferralIndex(referral, campaigns.length - 1);
			}
		}

		campaignsCreatedByAddress[owner]++;
		campaignToIndex[value.campaignId] = campaigns.length - 1;
		emit CampaignCreated(owner, campaigns.length);
	}

	function updateReferralIndex(address referral, uint256 campaignIndex)
		external
		onlyRole(WRITER_ROLE)
	{
		uint256 referralCampaignsCount = campaignsByAddressLength[referral];
		campaignsByAddress[referral][referralCampaignsCount]
			.campaignIndex = campaignIndex;
		campaignsByAddress[referral][referralCampaignsCount].userType = UserType
			.REFERRAL;
		campaignsByAddressLength[referral]++;
	}

	function getCampaign(uint256 record)
		external
		view
		returns (Campaign memory)
	{
		return campaigns[record];
	}

	function getCampaignCreatedByAddress(address addr)
		external
		view
		returns (uint256)
	{
		return campaignsCreatedByAddress[addr];
	}

	function getCampaignByAddressLength(address addr)
		external
		view
		returns (uint256)
	{
		return campaignsByAddressLength[addr];
	}

	function getCampaignsLength() external view returns (uint256) {
		return campaigns.length;
	}
}