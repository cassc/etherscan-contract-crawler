// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./MembershipsTypes.sol";
import "./HelperLib.sol";
import "./EternalStorage.sol";
import "./MembershipsImpl.sol";
import "./MembershipsErrors.sol";

contract Memberships is
	Ownable,
	Pausable,
	ReentrancyGuard,
	MembershipsTypes,
	MembershipsErrors
{
	using SafeERC20 for IERC20;

	address eternalStorage;
	address membershipsImpl;

	address private _rollWallet;
	uint256 private _minRollFee;

	uint256 constant BETA_PERIOD_DURATION = 6 * 30; // six months
	uint256 immutable betaPeriodExpiration;

	// ================
	// EVENTS
	// ================
	event EventScheduleCreated(
		address indexed from,
		bytes32 indexed scheduleId
	);

	event EventScheduleCreatedWithToken(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed token
	);

	event Revoked(bytes32 indexed scheduleId);

	event EventReferralUpdated(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed newReferral
	);

	event EventTokenAllowedUpdated(
		address indexed from,
		address indexed token,
		bool value
	);

	event EventMembershipsImplUpdated(
		address indexed from,
		address indexed addr
	);

	event EventRollWalletUpdated(address indexed from, address indexed addr);

	event EventEternalStorageUpdated(
		address indexed from,
		address indexed addr
	);

	event EventScheduleReferralSet(
		address indexed sender,
		bytes32 indexed scheduleId,
		address indexed referral,
		uint256 referralFee
	);

	event EventMinRollFeeUpdated(uint256 newMinRollFee);

	constructor(
		address eternalStorage_,
		address membershipsImpl_,
		address rollWallet,
		uint256 minRollFee
	) {
		if (
			eternalStorage_ == address(0) ||
			membershipsImpl_ == address(0) ||
			rollWallet == address(0)
		) {
			revert ErrorME13InvalidAddress();
		}
		eternalStorage = eternalStorage_;
		membershipsImpl = membershipsImpl_;
		_rollWallet = rollWallet;
		_minRollFee = minRollFee;
		betaPeriodExpiration = getCurrentTime() + BETA_PERIOD_DURATION * 1 days;
	}

	// ================
	// MODIFIERS
	// ================
	modifier onlyCampaignOwner(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (msg.sender != schedule.owner) {
			revert ErrorME05OnlyOwnerAllowed();
		}
		_;
	}

	modifier onlyIfScheduleNotRevoked(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (!schedule.initialized || schedule.revoked) {
			revert ErrorME07ScheduleRevoked();
		}
		_;
	}

	modifier onlyIfScheduleIsActive(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (
			!schedule.initialized ||
			schedule.revoked ||
			schedule.start > getCurrentTime() ||
			schedule.start + schedule.duration <= getCurrentTime()
		) {
			revert ErrorME08ScheduleNotActive();
		}
		_;
	}

	modifier onlyScheduleAlreadyFinish(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (schedule.start + schedule.duration >= getCurrentTime()) {
			revert ErrorME09ScheduleNotFinished();
		}
		_;
	}

	modifier onlyScheduleAlreadyFinishOrSoldOut(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (
			schedule.start + schedule.duration >= getCurrentTime() &&
			schedule.released != schedule.amountTotal
		) {
			revert ErrorME25ScheduleNotFinishedOrSoldOut();
		}
		_;
	}

	modifier onlyMembershipsImpl() {
		if (msg.sender != membershipsImpl) {
			revert ErrorME26OnlyMembershipsImpl();
		}
		_;
	}

	// ================
	// PUBLIC FUNCTIONS
	// ================
	/**
	 * @notice Creates a new schedule for a beneficiary.
	 */
	function createMintingSchedule(
		CreateMintingScheduleParams memory params,
		uint256 phaseIndex
	) internal returns (bytes32) {
		MembershipsImpl(membershipsImpl).createMintingScheduleValidation(
			params
		);
		if (
			params.rollFee < _minRollFee ||
			params.rollFee > HelperLib.FEE_SCALE ||
			(params.rollFee + params.referralFee > HelperLib.FEE_SCALE)
		) revert ErrorME01InvalidFee(_minRollFee, HelperLib.FEE_SCALE);

		// valid payments are ETH or allowed tokens
		if (
			params.paymentAsset.assetType == AssetType.ERC20 &&
			!MembershipsImpl(membershipsImpl).isTokenAllowed(
				params.paymentAsset.token
			)
		) revert ErrorME02TokenNotAllowed();

		// transfer the reward tokens to the contract
		for (uint256 i = 0; i < params.lotToken.length; i++) {
			IERC20 token = IERC20(params.lotToken[i]);
			token.safeIncreaseAllowance(
				membershipsImpl,
				params.lotSize[i] * params.amountTotal
			);

			token.safeTransferFrom(
				msg.sender,
				address(this),
				params.lotSize[i] * params.amountTotal
			);
		}

		if (params.paymentAsset.assetType == AssetType.ERC20) {
			IERC20 token = IERC20(params.paymentAsset.token);
			token.safeIncreaseAllowance(
				address(this),
				params.pricePerLot * params.amountTotal
			);
		}

		MintingSchedule memory m = MintingSchedule(
			true,
			false,
			msg.sender,
			params.start,
			params.duration,
			params.merkleRoot,
			params.amountTotal,
			0,
			params.lotToken,
			params.lotSize,
			params.paymentAsset,
			params.pricePerLot,
			params.rollFee,
			params.maxBuyPerWallet
		);

		bytes32 scheduleId = computeNextScheduleIdForHolder(
			msg.sender,
			phaseIndex
		);
		MembershipsImpl(membershipsImpl).setSchedule(scheduleId, m);

		if (params.referral != address(0)) {
			MembershipsImpl(membershipsImpl).setReferral(
				scheduleId,
				ScheduleReferral(params.referral, params.referralFee)
			);
			emit EventScheduleReferralSet(
				msg.sender,
				scheduleId,
				params.referral,
				params.referralFee
			);
		}

		emit EventScheduleCreated(msg.sender, scheduleId);
		for (uint256 i = 0; i < params.lotToken.length; i++) {
			emit EventScheduleCreatedWithToken(
				msg.sender,
				scheduleId,
				params.lotToken[i]
			);
		}

		return scheduleId;
	}

	function createCampaign(
		CreateMintingScheduleParams[] memory params,
		string memory metadata
	) external nonReentrant whenNotPaused {
		uint256 phasesLength = uint256(params.length);
		if (phasesLength < 1) revert ErrorME04NotEnoughPhases();

		Campaign memory campaign = Campaign({
			campaignId: "",
			phases: new bytes32[](phasesLength),
			metadata: metadata
		});
		for (uint256 i = 0; i < phasesLength; i++) {
			bytes32 scheduleId = createMintingSchedule(params[i], i);
			campaign.phases[i] = scheduleId;
		}
		campaign.campaignId = campaign.phases[0];
		MembershipsImpl(membershipsImpl).addCampaign(campaign);
	}

	/**
	 * @notice Revokes the vesting schedule for given identifier.
	 */
	function revoke(bytes32 scheduleId)
		external
		onlyCampaignOwner(scheduleId)
		onlyIfScheduleNotRevoked(scheduleId)
		whenNotPaused
	{
		MembershipsImpl(membershipsImpl).revoke(scheduleId);
	}

	/**
	 * @notice Updates the campaign metadata.
	 */
	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) external onlyCampaignOwner(campaignId) whenNotPaused {
		MembershipsImpl(membershipsImpl).updateCampaignMetadata(
			campaignId,
			metadata
		);
	}

	/**
	 * @notice In original contract this method is called Withdraw
	 */
	function claim(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claim(address(this), scheduleId);
	}

	function claimRoll(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimRoll(
			address(this),
			_rollWallet,
			scheduleId
		);
	}

	function claimReferral(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimReferral(
			address(this),
			scheduleId
		);
	}

	function claimUnsoldTokens(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinish(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimUnsoldTokens(
			address(this),
			scheduleId
		);
	}

	/**
	 * @notice Buy method when there's no allowlist
	 */
	function buy(bytes32 scheduleId, uint256 amount)
		external
		payable
		whenNotPaused
		nonReentrant
		onlyIfScheduleIsActive(scheduleId)
	{
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (schedule.merkleRoot != bytes32("")) {
			revert ErrorME10ActionAllowlisted();
		}

		MembershipsImpl(membershipsImpl).buy(
			address(this),
			msg.sender,
			scheduleId,
			amount,
			msg.value
		);
	}

	/**
	 * @notice Buy method when there's an allowlist
	 */
	function buyWithAllowlist(
		bytes32 scheduleId,
		uint256 amount,
		bytes32[] memory proof
	)
		external
		payable
		whenNotPaused
		nonReentrant
		onlyIfScheduleIsActive(scheduleId)
	{
		MembershipsImpl(membershipsImpl).verifyMerkle(
			msg.sender,
			scheduleId,
			proof
		);

		MembershipsImpl(membershipsImpl).buy(
			address(this),
			msg.sender,
			scheduleId,
			amount,
			msg.value
		);
	}

	function doTransfer(
		AssetType assetType,
		address tokenAddress,
		address from,
		address to,
		uint256 value
	) external onlyMembershipsImpl {
		if (to == address(0)) revert ErrorME13InvalidAddress();

		if (assetType == AssetType.ETH) {
			(bool sent, ) = to.call{ value: value }("");
			if (!sent) revert ErrorME11TransferError();
		} else {
			IERC20 token = IERC20(tokenAddress);
			token.safeTransferFrom(from, to, value);
		}
	}

	// ================
	// ADMIN FUNCTIONS
	// ================

	// set a new merkle tree root
	function setAllowlist(bytes32 scheduleId, bytes32 root)
		external
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).setAllowlist(scheduleId, root);
	}

	// transfer the ownership
	function transferScheduleOwner(bytes32 scheduleId, address owner_)
		external
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).transferScheduleOwner(
			scheduleId,
			owner_
		);
	}

	// change referral
	function updateReferral(bytes32 scheduleId, address referral)
		external
		nonReentrant
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).updateReferral(scheduleId, referral);
		emit EventReferralUpdated(msg.sender, scheduleId, referral);
	}

	// ================
	// GETTER FUNCTIONS
	// ================

	/**
	 * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
	 * @return the vested amount
	 */
	function computeUnsoldLots(bytes32 scheduleId)
		external
		view
		onlyIfScheduleNotRevoked(scheduleId)
		returns (uint256)
	{
		return MembershipsImpl(membershipsImpl).computeUnsoldLots(scheduleId);
	}

	/**
	 * @dev Computes the next vesting schedule identifier for a given holder address.
	 */
	function computeNextScheduleIdForHolder(address holder, uint256 phaseIndex)
		internal
		view
		returns (bytes32)
	{
		return
			computeScheduleIdForAddressAndIndex(
				holder,
				phaseIndex,
				MembershipsImpl(membershipsImpl).getCampaignCreatedByAddress(
					holder
				)
			);
	}

	/**
	 * @dev Computes the vesting schedule identifier for an address and an index.
	 */
	function computeScheduleIdForAddressAndIndex(
		address holder,
		uint256 index,
		uint256 length
	) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(holder, index, length));
	}

	function getMinRollFee() external view returns (uint256) {
		return _minRollFee;
	}

	// ==================
	// ROLL ADMIN FUNCTIONS
	// ==================
	function setRollWallet(address newRollWallet) external onlyOwner {
		if (newRollWallet == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		_rollWallet = newRollWallet;
		emit EventRollWalletUpdated(msg.sender, newRollWallet);
	}

	function setMinRollFee(uint256 newMinRollFee) external onlyOwner {
		if (newMinRollFee >= HelperLib.FEE_SCALE)
			revert ErrorME01InvalidFee(newMinRollFee, HelperLib.FEE_SCALE);

		_minRollFee = newMinRollFee;
		emit EventMinRollFeeUpdated(newMinRollFee);
	}

	function setTokenAllow(address token, bool value) external onlyOwner {
		if (token == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		MembershipsImpl(membershipsImpl).setTokensAllowed(token, value);
		emit EventTokenAllowedUpdated(msg.sender, token, value);
	}

	function setEternalStorageAddress(address addr) external onlyOwner {
		if (addr == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		eternalStorage = addr;

		emit EventEternalStorageUpdated(msg.sender, addr);
	}

	function setMembershipsImplAddress(address addr) external onlyOwner {
		if (addr == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		membershipsImpl = addr;

		emit EventMembershipsImplUpdated(msg.sender, addr);
	}

	function pause() external onlyOwner {
		if (betaPeriodExpiration < getCurrentTime())
			revert ErrorME14BetaPeriodAlreadyFinish();
		_pause();
	}

	// ==================
	// INTERNAL FUNCTIONS
	// ==================

	function getCurrentTime() internal view virtual returns (uint256) {
		return block.timestamp;
	}
}