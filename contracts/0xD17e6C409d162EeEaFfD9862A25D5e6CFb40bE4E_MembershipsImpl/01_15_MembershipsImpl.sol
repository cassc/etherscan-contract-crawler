// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./MembershipsTypes.sol";
import "./HelperLib.sol";
import "./EternalStorage.sol";
import "./MembershipsErrors.sol";

interface IMemberships {
	function doTransfer(
		MembershipsTypes.AssetType assetType,
		address token,
		address from,
		address to,
		uint256 value
	) external;
}

contract MembershipsImpl is MembershipsTypes, AccessControl, MembershipsErrors {
	using SafeERC20 for IERC20;

	bytes32 public constant MEMBERSHIP_ROLE = keccak256("MEMBERSHIP_ROLE");
	EternalStorage private _eternalStorage;

	event EventAllowlistUpdated(
		bytes32 indexed scheduleId,
		bytes32 indexed newRoot
	);

	event EventScheduleOwnerTransferred(
		bytes32 indexed scheduleId,
		address indexed oldOwner,
		address indexed newOwner
	);

	event EventScheduleRevoked(bytes32 indexed scheduleId);

	event EventUnsoldTokensClaimed(
		address indexed memberships,
		bytes32 indexed scheduleId,
		uint256 amount
	);

	// @dev: we emit two kind of event, one per buy and one per token
	event EventBuyLot(
		address indexed from,
		bytes32 indexed scheduleId,
		uint256 lots
	);

	event EventBuyToken(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed token,
		uint256 tokens
	);

	event EventClaim(
		address indexed from,
		bytes32 indexed scheduleId,
		uint256 value
	);

	constructor(address eternalStorage) {
		if (eternalStorage == address(0)) {
			revert ErrorME13InvalidAddress();
		}

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		_eternalStorage = EternalStorage(eternalStorage);
	}

	// ==================
	// STORAGE GET/SET
	// ==================
	function getCampaignCreatedByAddress(address addr)
		external
		view
		returns (uint256)
	{
		return _eternalStorage.getCampaignCreatedByAddress(addr);
	}

	function getBuyPerWallet(bytes32 scheduleId, address addr)
		internal
		view
		returns (uint256)
	{
		return _eternalStorage.getBuyPerWallet(scheduleId, addr);
	}

	function setBuyPerWallet(
		bytes32 scheduleId,
		address addr,
		uint256 value
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.setBuyPerWallet(scheduleId, addr, value);
	}

	function isTokenAllowed(address addr) external view returns (bool) {
		return _eternalStorage.isTokenAllowed(addr);
	}

	function getTokensAllowed() internal view returns (address[] memory) {
		return _eternalStorage.getTokensAllowed();
	}

	function setTokensAllowed(address token, bool value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setTokensAllowed(token, value);
	}

	function getClaimed(bytes32 scheduleId, UserType userType)
		public
		view
		returns (uint256)
	{
		return _eternalStorage.getClaimed(scheduleId, userType);
	}

	function setClaimed(
		bytes32 scheduleId,
		UserType userType,
		uint256 value
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.setClaimed(scheduleId, userType, value);
	}

	function addCampaign(Campaign memory value)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.addCampaign(value);
	}

	function getSchedule(bytes32 record)
		public
		view
		returns (MintingSchedule memory)
	{
		return _eternalStorage.getSchedule(record);
	}

	function setSchedule(bytes32 record, MintingSchedule memory value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setSchedule(record, value);
	}

	function getReferral(bytes32 record)
		public
		view
		returns (ScheduleReferral memory)
	{
		return _eternalStorage.getReferral(record);
	}

	function setReferral(bytes32 record, ScheduleReferral memory value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setReferral(record, value);
	}

	function _removeReferral(bytes32 record, address oldReferral)
		internal
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.removeReferral(record, oldReferral);
	}

	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.updateCampaignMetadata(campaignId, metadata);
	}

	// ==================
	// VALIDATORS
	// ==================
	function createMintingScheduleValidation(
		CreateMintingScheduleParams calldata params
	) external view {
		if (params.start < getCurrentTime()) revert ErrorME15InvalidDate();
		if (params.duration == 0) revert ErrorME16InvalidDuration();
		if (params.pricePerLot == 0) revert ErrorME17InvalidPrice();
		if (
			params.lotToken.length == 0 ||
			params.lotSize.length == 0 ||
			params.lotToken.length != params.lotSize.length
		) revert ErrorME18LotArrayLengthMismatch();
		if (
			(params.referral != address(0) || params.referralFee != 0) &&
			(params.referral == address(0) || params.referralFee == 0)
		) revert ErrorME20InvalidReferral();
		if (params.referralFee >= HelperLib.FEE_SCALE)
			revert ErrorME21InvalidReferralFee();
		if (params.amountTotal == 0) revert ErrorME28InvalidAmount();
		if (params.maxBuyPerWallet == 0)
			revert ErrorME29InvalidMaxBuyPerWallet();
	}

	// ==================
	// BUY / CLAIM FUNCTIONS
	// ==================

	function buy(
		address memberships,
		address caller,
		bytes32 scheduleId,
		uint256 amount,
		uint256 msgValue
	) external onlyRole(MEMBERSHIP_ROLE) {
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 callerPreviousAmount = getBuyPerWallet(scheduleId, caller);

		if (amount + schedule.released > schedule.amountTotal)
			revert ErrorME27TotalAmountExceeded();

		if (amount + callerPreviousAmount > schedule.maxBuyPerWallet)
			revert ErrorME22MaxBuyPerWalletExceeded();

		if (schedule.paymentAsset.assetType == AssetType.ETH) {
			if (msgValue != schedule.pricePerLot * amount)
				revert ErrorME19NotEnoughEth();
		} else {
			IERC20 token = IERC20(schedule.paymentAsset.token);
			token.safeTransferFrom(
				caller,
				memberships,
				schedule.pricePerLot * amount
			);
		}
		schedule.released = schedule.released + amount;
		setSchedule(scheduleId, schedule);
		setBuyPerWallet(scheduleId, caller, callerPreviousAmount + amount);
		for (uint256 i = 0; i < schedule.lotToken.length; i++) {
			IERC20 token = IERC20(schedule.lotToken[i]);
			token.safeTransferFrom(
				memberships,
				caller,
				schedule.lotSize[i] * amount
			);

			emit EventBuyToken(
				caller,
				scheduleId,
				schedule.lotToken[i],
				schedule.lotSize[i] * amount
			);
		}

		emit EventBuyLot(caller, scheduleId, amount);
	}

	/**
	 * @notice In original contract this method is called Withdraw
	 */
	function claim(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 earned = schedule.pricePerLot * schedule.released;

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.OWNER
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		uint256 referralFee = getReferral(scheduleId).referralFee;

		earned =
			earned -
			HelperLib.getFeeFraction(earned, schedule.rollFee) -
			HelperLib.getFeeFraction(earned, referralFee);

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			schedule.owner,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.OWNER, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimRoll(
		address memberships,
		address wallet,
		bytes32 scheduleId
	) external onlyRole(MEMBERSHIP_ROLE) {
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 earned = HelperLib.getFeeFraction(
			schedule.pricePerLot * schedule.released,
			schedule.rollFee
		);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.ROLL
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			wallet,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.ROLL, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimReferral(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		ScheduleReferral memory scheduleR = getReferral(scheduleId);

		uint256 earned = HelperLib.getFeeFraction(
			schedule.pricePerLot * schedule.released,
			scheduleR.referralFee
		);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.REFERRAL
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			scheduleR.referral,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.REFERRAL, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimUnsoldTokens(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.UNSOLD
		);

		if (
			schedule.amountTotal - schedule.released != 0 &&
			totalClaimed == (schedule.amountTotal - schedule.released)
		) revert ErrorME23TotalClaimedError();

		for (uint256 i = 0; i < schedule.lotToken.length; i++) {
			IERC20 token = IERC20(schedule.lotToken[i]);
			token.safeTransferFrom(
				memberships,
				schedule.owner,
				schedule.lotSize[i] * (schedule.amountTotal - schedule.released)
			);
		}

		setClaimed(
			scheduleId,
			MembershipsTypes.UserType.UNSOLD,
			(schedule.amountTotal - schedule.released)
		);

		emit EventUnsoldTokensClaimed(
			memberships,
			scheduleId,
			schedule.amountTotal - schedule.released
		);
	}

	function verifyMerkle(
		address caller,
		bytes32 scheduleId,
		bytes32[] memory proof
	) external view {
		MintingSchedule memory schedule = getSchedule(scheduleId);
		// Verify merkle proof
		bytes32 leaf = keccak256(abi.encodePacked(caller));

		if (!MerkleProof.verify(proof, schedule.merkleRoot, leaf))
			revert ErrorME24InvalidProof();
	}

	// ================
	// OWNER ADMIN FUNCTIONS
	// ================

	// set a new merkle tree root
	function setAllowlist(bytes32 scheduleId, bytes32 root)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory s = getSchedule(scheduleId);
		if (s.merkleRoot != root) {
			s.merkleRoot = root;
			setSchedule(scheduleId, s);
			emit EventAllowlistUpdated(scheduleId, root);
		}
	}

	// transfer the ownership
	function transferScheduleOwner(bytes32 scheduleId, address owner_)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory s = getSchedule(scheduleId);
		if (s.owner != owner_) {
			address oldOwner = s.owner;
			s.owner = owner_;
			setSchedule(scheduleId, s);
			emit EventScheduleOwnerTransferred(scheduleId, oldOwner, owner_);
		}
	}

	// change referral
	function updateReferral(bytes32 scheduleId, address referral)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		ScheduleReferral memory s = getReferral(scheduleId);
		address oldReferral = s.referral;
		s.referral = referral;

		(, uint256 campaignIndex, ) = _eternalStorage.scheduleToCampaign(
			scheduleId
		);

		setReferral(scheduleId, s);
		_eternalStorage.updateReferralIndex(referral, campaignIndex);

		if (oldReferral != address(0)) {
			_removeReferral(scheduleId, oldReferral);
		}
	}

	function revoke(bytes32 scheduleId) external onlyRole(MEMBERSHIP_ROLE) {
		MembershipsTypes.MintingSchedule memory schedule = getSchedule(
			scheduleId
		);
		schedule.revoked = true;
		setSchedule(scheduleId, schedule);
		emit EventScheduleRevoked(scheduleId);
	}

	// ==================
	// INTERNAL IMPL
	// ==================

	/**
	 * @dev Computes the releasable amount of tokens for a vesting schedule.
	 * @return the amount of releasable tokens
	 */
	function computeUnsoldLots(bytes32 scheduleId)
		external
		view
		returns (uint256)
	{
		MembershipsTypes.MintingSchedule memory schedule = getSchedule(
			scheduleId
		);
		uint256 currentTime = getCurrentTime();
		if (schedule.revoked) {
			return 0;
		} else if (currentTime >= schedule.start + schedule.duration) {
			return schedule.amountTotal - schedule.released;
		}
		return 0;
	}

	// ==================
	// INTERNAL FUNCTIONS
	// ==================

	function getCurrentTime() internal view virtual returns (uint256) {
		return block.timestamp;
	}
}