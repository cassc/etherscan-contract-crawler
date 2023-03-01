// SPDX-License-Identifier: UNLICENSED

/**
 *  @authors: [@greenlucid]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.16;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@kleros/dispute-resolver-interface-contract/contracts/IDisputeResolver.sol";

interface WXDAI is IERC20 {
	function deposit() external payable;
}

contract Yubiai is IDisputeResolver {
	// None: Deal hasn't even begun.
	// Ongoing: Exists, it's not currently being claimed.
	// Claimed: The seller made a claim to obtain a refund.
	// Disputed: A claim on this deal is being disputed.
	// Finished: It's over.
	enum DealState {
		None,
		Ongoing,
		Claimed,
		Disputed,
		Finished
	}

	enum ClaimResult {
		Rejected,
		Accepted
	}

	// Round struct stores the contributions made to particular rulings.
	struct Round {
		mapping(uint256 => uint256) paidFees; // Tracks the fees paid in this round in the form paidFees[ruling].
		mapping(uint256 => bool) hasPaid; // True if the fees for this particular ruling have been fully paid in the form hasPaid[ruling].
		mapping(address => mapping(uint256 => uint256)) contributions; // Maps contributors to their contributions for each ruling in the form contributions[address][answer].
		uint256 feeRewards; // Sum of reimbursable appeal fees available to the parties that made contributions to the ruling that ultimately wins a dispute.
		uint256[] fundedAnswers; // Stores the choices that are fully funded.
	}

	struct Claim {
		uint256 disputeId;
		uint256 amount;
		uint256 arbFees;
		//
		uint64 dealId;
		uint32 createdAt;
		uint32 solvedAt; // if zero, unsolved yet.
		uint8 ruling;
		uint64 arbSettingsId;
		uint56 freeSpace;
		//
		Round[] rounds;
	}

	struct Deal {
		uint256 amount;
		//
		address buyer;
		DealState state;
		uint32 extraBurnFee;
		uint32 claimCount;
		uint24 freeSpace;
		//
		address seller;
		uint32 createdAt;
		uint32 timeForService;
		uint32 timeForClaim;
		//
		IERC20 token;
		uint64 currentClaim;
		uint32 freeSpace2;
	}

	struct YubiaiSettings {
		address admin;
		uint32 maxClaims; // max n claims per deal. a deal is automatically closed if last claim fails.
		uint32 timeForReclaim; // time the buyer has to create new claim after losing prev
		uint32 timeForChallenge; // time the seller has to challenge a claim, and accepted otherwise.
		//
		address ubiBurner;
		// fees are in basis points
		uint32 adminFee;
		uint32 ubiFee;
		uint32 maxExtraFee; // this must be at all times under 10000 to prevent drain attacks.
		// ---
		// enforce timespans for prevent attacks
		uint32 minTimeForService;
		uint32 maxTimeForService;
		uint32 minTimeForClaim;
		uint32 maxTimeForClaim;
	}

	struct Counters {
		uint64 dealCount;
		uint64 claimCount;
		uint64 currentArbSettingId;
	}

	event DealCreated(uint64 indexed dealId, Deal deal, string terms);
	event ClaimCreated(uint64 indexed dealId, uint64 indexed claimId, uint256 amount, string evidence);

	event ClaimClosed(uint64 indexed claimId, ClaimResult indexed result);

	event DealClosed(uint64 indexed dealId, uint256 payment, uint256 refund, uint256 ubiFee, uint256 adminFee);

	/// 0: Refuse to Arbitrate (Don't refund)
	/// 1: Don't refund
	/// 2: Refund
	uint256 constant NUMBER_OF_RULINGS = 2;

	uint256 constant BASIS_POINTS = 10_000;

	// hardcoded the multipliers for efficiency. they've been shown to work fine.
	uint256 constant WINNER_STAKE_MULTIPLIER = 5_000;
	uint256 constant LOSER_STAKE_MULTIPLIER = 10_000;
	uint256 constant LOSER_APPEAL_PERIOD_MULTIPLIER = 5_000;

	// used for automatically creating deals with wrapped value
	WXDAI constant wxdai = WXDAI(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

	Counters public counters;
	YubiaiSettings public settings;
	address public governor;

	mapping(uint64 => Deal) public deals;
	mapping(uint64 => Claim) public claims;

	IArbitrator public arbitrator;
	mapping(uint256 => uint64) public disputeIdToClaim;
	mapping(uint64 => bytes) public extraDatas;
	mapping(IERC20 => bool) public tokenValidity;

	/**
	 * @dev Initializes the contract.
	 * @param _settings Initial settings of Yubiai.
	 * @param _governor Governor of Yubiai, can change settings.
	 * @param _metaEvidence The immutable metaEvidence.
	 */
	constructor(
		YubiaiSettings memory _settings,
		address _governor,
		IArbitrator _arbitrator,
		bytes memory _extraData,
		string memory _metaEvidence
	) {
		settings = _settings;
		governor = _governor;
		arbitrator = _arbitrator;
		extraDatas[0] = _extraData;
		emit MetaEvidence(0, _metaEvidence);
	}

	/**
	 * @dev Change settings of Yubiai, only governor.
	 * @param _settings New settings.
	 */
	function changeSettings(YubiaiSettings memory _settings) external {
		require(msg.sender == governor, "Only governor");
		settings = _settings;
	}

	/**
	 * @dev Change governor of Yubiai, only governor.
	 * @param _governor New governor.
	 */
	function changeGovernor(address _governor) external {
		require(msg.sender == governor, "Only governor");
		governor = _governor;
	}

	/**
	 * @dev Change arbSettings of Yubiai, only governor.
	 * @param _extraData New arbitratorExtraData
	 * @param _metaEvidence New MetaEvidence
	 */
	function newArbSettings(bytes calldata _extraData, string calldata _metaEvidence) external {
		require(msg.sender == governor, "Only governor");
		counters.currentArbSettingId++;
		extraDatas[counters.currentArbSettingId] = _extraData;
		emit MetaEvidence(counters.currentArbSettingId, _metaEvidence);
	}

	/**
	 * @dev Toggle validity on an ERC20 token, only governor.
	 * @param _token Token to change validity of.
	 * @param _validity Whether if it's valid or not.
	 */
	function setTokenValidity(IERC20 _token, bool _validity) external {
		require(msg.sender == governor, "Only governor");
		tokenValidity[_token] = _validity;
	}

	/**
	 * @dev Creates a deal, an agreement between buyer and seller.
	 * @param _deal The deal that is to be created. Some properties may be mutated.
	 * @param _terms An IPFS link giving extra context of the terms of the deal.
	 */
	function createDeal(Deal memory _deal, string memory _terms) public {
		require(_deal.token.transferFrom(msg.sender, address(this), _deal.amount), "Token transfer failed");
		// offering received. that's all you need.
		_deal.createdAt = uint32(block.timestamp);
		_deal.state = DealState.Ongoing;
		_deal.claimCount = 0;
		_deal.currentClaim = 0;
		// additional validation could take place here:
		// verify max extra fee
		require(_deal.extraBurnFee <= settings.maxExtraFee, "Extra fee too large");
		// only allowed tokens
		require(tokenValidity[_deal.token], "Invalid token");
		// only allowed time spans
		require(_deal.timeForService >= settings.minTimeForService, "Too little time for service");
		require(_deal.timeForClaim >= settings.minTimeForClaim, "Too little time for claim");
		require(_deal.timeForService <= settings.maxTimeForService, "Too much time for service");
		require(_deal.timeForClaim <= settings.maxTimeForClaim, "Too much time for claim");

		deals[counters.dealCount] = _deal;
		emit DealCreated(counters.dealCount, _deal, _terms);
		counters.dealCount++;
	}

	/**
	 * @dev Like createDeal, but with msg.value, allowing users to not need to wrap xDAI.
	 *  The seller (or buyer, in case refunds occur) will receive WXDAI, though.
	 * @param _deal The deal that is to be created. Some properties may be mutated.
	 * @param _terms An IPFS link giving extra context of the terms of the deal.
	 */
	function createDealWithValue(Deal memory _deal, string memory _terms) public payable {
		// wrap the value
		wxdai.deposit{value: msg.value}();
		_deal.amount = msg.value;
		_deal.token = wxdai;
		// the rest of the function is pretty much a copy of the regular createDeal
		_deal.createdAt = uint32(block.timestamp);
		_deal.state = DealState.Ongoing;
		_deal.claimCount = 0;
		_deal.currentClaim = 0;

		// verify max extra fee
		require(_deal.extraBurnFee <= settings.maxExtraFee, "Extra fee too large");
		// only allowed time spans
		require(_deal.timeForService >= settings.minTimeForService, "Too little time for service");
		require(_deal.timeForClaim >= settings.minTimeForClaim, "Too little time for claim");
		require(_deal.timeForService <= settings.maxTimeForService, "Too much time for service");
		require(_deal.timeForClaim <= settings.maxTimeForClaim, "Too much time for claim");
		deals[counters.dealCount] = _deal;
		emit DealCreated(counters.dealCount, _deal, _terms);
		counters.dealCount++;
	}

	/**
	 * @dev Closes a deal. Different actors can close the deal, depending on some conditions.
	 * @param _dealId The ID of the deal to be closed.
	 */
	function closeDeal(uint64 _dealId) public {
		Deal storage deal = deals[_dealId];
		require(deal.state == DealState.Ongoing, "Deal is not ongoing");
		// 1. if over the time for service + claim, anyone can close it.
		if (isOver(_dealId)) {
			_closeDeal(_dealId, deal.amount);
		} else {
			// 2. if under, the buyer can decide to pay the seller.
			require(deal.buyer == msg.sender, "Only buyer can forward payment");
			_closeDeal(_dealId, deal.amount);
		}
	}

	/**
	 * @dev Make a claim on an existing deal. Only the buyer can claim.
	 * @param _dealId The ID of the deal to make a claim on.
	 * @param _amount Amount to be refunded.
	 * @param _evidence Rationale behind the requested refund.
	 */
	function makeClaim(uint64 _dealId, uint256 _amount, string calldata _evidence) external payable {
		Deal storage deal = deals[_dealId];
		require(msg.sender == deal.buyer, "Only buyer");
		require(deal.amount >= _amount, "Refund cannot be greater than deal");
		require(
			deal.state == DealState.Ongoing &&
				block.timestamp >= (deal.createdAt + deal.timeForService) &&
				!isOver(_dealId),
			"Deal cannot be claimed"
		);
		uint256 arbFees = arbitrator.arbitrationCost(extraDatas[counters.currentArbSettingId]);
		require(msg.value >= arbFees, "Not enough to cover fees");
		Claim storage claim = claims[counters.claimCount];
		claim.dealId = _dealId;
		claim.amount = _amount;
		claim.createdAt = uint32(block.timestamp);
		claim.arbSettingsId = counters.currentArbSettingId;

		deal.state = DealState.Claimed;
		deal.claimCount++;
		deal.currentClaim = counters.claimCount;
		emit ClaimCreated(_dealId, counters.claimCount, _amount, _evidence);
		counters.claimCount++;
	}

	/**
	 * @dev Accept the claim and pay the refund, only by seller.
	 * @param _claimId The ID of the claim to accept.
	 */
	function acceptClaim(uint64 _claimId) public {
		Claim storage claim = claims[_claimId];
		Deal storage deal = deals[claim.dealId];
		require(deal.state == DealState.Claimed, "Deal is not Claimed");
		if (block.timestamp >= claim.createdAt + settings.timeForChallenge) {
			// anyone can force a claim that went over the period
		} else {
			// only the seller can accept it
			require(deal.seller == msg.sender, "Only seller");
		}

		uint256 arbFees = arbitrator.arbitrationCost(extraDatas[claim.arbSettingsId]);
		_closeDeal(claim.dealId, deal.amount - claim.amount);
		claim.solvedAt = uint32(block.timestamp);
		deal.token.transfer(deal.buyer, claim.amount);
		emit ClaimClosed(_claimId, ClaimResult.Accepted);
		payable(deal.buyer).send(arbFees); // it is the buyer responsibility to accept eth.
	}

	/**
	 * @dev Challenge a refund claim, only by seller. A dispute will be created.
	 * @param _claimId The ID of the claim to challenge.
	 */
	function challengeClaim(uint64 _claimId) public payable {
		Claim storage claim = claims[_claimId];
		Deal storage deal = deals[claim.dealId];
		require(msg.sender == deal.seller, "Only seller");
		require(deal.state == DealState.Claimed, "Deal is not Claimed");
		require(block.timestamp < claim.createdAt + settings.timeForChallenge, "Too late for challenge");

		// if arbFees are updated between the period the claim is created and challenged:
		// 1. they rise, so someone should cover the difference so that arbFees are returned
		//  to winner on rule(...), and prevent contract from halting.
		// 2. they are lowered, so someone should send the difference to the claimer
		//  whether they win or lose.
		uint256 arbFees = arbitrator.arbitrationCost(extraDatas[claim.arbSettingsId]);
		require(msg.value >= arbFees, "Not enough to cover fees");

		// all good now.
		uint256 disputeId = arbitrator.createDispute{value: arbFees}(
			NUMBER_OF_RULINGS,
			extraDatas[claim.arbSettingsId]
		);
		disputeIdToClaim[disputeId] = _claimId;
		claim.disputeId = disputeId;
		claim.arbFees = arbFees;
		deal.state = DealState.Disputed;
		// initializes the round array
		claim.rounds.push();

		emit Dispute(arbitrator, disputeId, claim.arbSettingsId, _claimId);
	}

	/**
	 * @dev Rule on a claim, only by arbitrator.
	 * @param _disputeId The external ID of the dispute.
	 * @param _ruling The ruling. 0 and 1 will not refund, 2 will refund.
	 */
	function rule(uint256 _disputeId, uint256 _ruling) external {
		require(msg.sender == address(arbitrator), "Only arbitrator rules");
		uint64 claimId = disputeIdToClaim[_disputeId];
		Claim storage claim = claims[claimId];
		Deal storage deal = deals[claim.dealId];
		require(deal.state == DealState.Disputed, "Deal is not Disputed");
		claim.solvedAt = uint32(block.timestamp);
		claim.ruling = uint8(_ruling);
		deal.state = DealState.Ongoing; // will be overwritten if needed.
		// if 0 (RtA) or 1 (Don't refund)...
		if (_ruling < 2) {
			// was this the last claim? if so, close deal with everything
			if (deal.claimCount >= settings.maxClaims) {
				_closeDeal(claim.dealId, deal.amount);
			}
			payable(deal.seller).send(claim.arbFees);
			emit ClaimClosed(claimId, ClaimResult.Rejected);
		} else {
			deal.token.transfer(deal.buyer, claim.amount);
			_closeDeal(claim.dealId, deal.amount - claim.amount);
			// refund buyer
			payable(deal.buyer).send(claim.arbFees);
			emit ClaimClosed(claimId, ClaimResult.Accepted);
		}
		emit Ruling(arbitrator, _disputeId, _ruling);
	}

	/**
	 * @dev Read whether if a deal is over or not.
	 * @param _dealId Id of the deal to check.
	 */
	function isOver(uint64 _dealId) public view returns (bool) {
		Deal memory deal = deals[_dealId];
		// if finished, then it's "over"
		if (deal.state == DealState.Finished) return (true);
		// if none, it hasn't even begun. if claimed or disputed, it can't be over yet.
		if (deal.state != DealState.Ongoing) return (false);
		// so, it's Ongoing. if no claims, then createdAt is the reference
		if (deal.claimCount == 0) {
			return (block.timestamp >= (deal.createdAt + deal.timeForService + deal.timeForClaim));
		} else {
			// if was ever claimed, the date of the last claim being solved is the reference.
			return (block.timestamp >= (claims[deal.currentClaim].solvedAt + settings.timeForReclaim));
		}
	}

	/**
	 * @dev Internal function to close the deal. It will process the fees
	 * @param _dealId Id of the deal to check.
	 */
	function _closeDeal(uint64 _dealId, uint256 _amount) internal {
		Deal storage deal = deals[_dealId];

		uint256 ubiFee = (_amount * (settings.ubiFee + deal.extraBurnFee)) / BASIS_POINTS;
		uint256 adminFee = (_amount * settings.adminFee) / BASIS_POINTS;

		uint256 toSeller = _amount - ubiFee - adminFee;

		deal.state = DealState.Finished;
		deal.token.transfer(deal.seller, toSeller);
		deal.token.transfer(settings.admin, adminFee);
		deal.token.transfer(settings.ubiBurner, ubiFee);

		emit DealClosed(_dealId, toSeller, deal.amount - _amount, ubiFee, adminFee);
	}

	// IDisputeResolver VIEWS

	/** @dev Maps external (arbitrator side) dispute id to local (arbitrable) dispute id.
	 *  @param _externalDisputeID Dispute id as in arbitrator contract.
	 *  @return localDisputeID Dispute id as in arbitrable contract.
	 */
	function externalIDtoLocalID(uint256 _externalDisputeID) external view override returns (uint256 localDisputeID) {
		localDisputeID = disputeIdToClaim[_externalDisputeID];
	}

	/** @dev Returns number of possible ruling options. Valid rulings are [0, return value].
	 *  @return count The number of ruling options.
	 */
	function numberOfRulingOptions(uint256) external pure override returns (uint256 count) {
		count = NUMBER_OF_RULINGS;
	}

	/** @dev Allows to submit evidence for a given dispute.
	 *  @param _claimId Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
	 *  @param _evidenceURI IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
	 */
	function submitEvidence(uint256 _claimId, string calldata _evidenceURI) external override {
		emit Evidence(arbitrator, _claimId, msg.sender, _evidenceURI);
	}

	/** @dev Returns appeal multipliers.
	 *  @return winnerStakeMultiplier Winners stake multiplier.
	 *  @return loserStakeMultiplier Losers stake multiplier.
	 *  @return loserAppealPeriodMultiplier Losers appeal period multiplier. The loser is given less time to fund its appeal to defend against last minute appeal funding attacks.
	 *  @return denominator Multiplier denominator in basis points.
	 */
	function getMultipliers() external pure override returns (uint256, uint256, uint256, uint256) {
		return (WINNER_STAKE_MULTIPLIER, LOSER_STAKE_MULTIPLIER, LOSER_APPEAL_PERIOD_MULTIPLIER, BASIS_POINTS);
	}

	// IDisputeResolver APPEALS

	/** @dev Manages contributions and calls appeal function of the specified arbitrator to appeal a dispute. This function lets appeals be crowdfunded.
	 *  @param _claimId Identifier of a dispute in scope of arbitrable contract. Arbitrator ids can be translated to local ids via externalIDtoLocalID.
	 *  @param _ruling The ruling option to which the caller wants to contribute.
	 *  @return fullyFunded True if the ruling option got fully funded as a result of this contribution.
	 */
	function fundAppeal(uint256 _claimId, uint256 _ruling) external payable override returns (bool fullyFunded) {
		Claim storage claim = claims[uint64(_claimId)];
		Deal storage deal = deals[claim.dealId];
		require(deal.state == DealState.Disputed, "No dispute to appeal.");
		require(_ruling < 3, "Invalid ruling");
		uint256 disputeId = claim.disputeId;
		(uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(disputeId);
		require(block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, "Appeal period is over.");

		uint256 multiplier;
		{
			uint256 winner = arbitrator.currentRuling(disputeId);
			if (winner == _ruling) {
				multiplier = WINNER_STAKE_MULTIPLIER;
			} else {
				require(
					block.timestamp - appealPeriodStart <
						((appealPeriodEnd - appealPeriodStart) * LOSER_APPEAL_PERIOD_MULTIPLIER) / BASIS_POINTS,
					"Appeal period is over for loser"
				);
				multiplier = LOSER_STAKE_MULTIPLIER;
			}
		}

		uint256 lastRoundID = claim.rounds.length - 1;
		Round storage round = claim.rounds[lastRoundID];
		require(!round.hasPaid[_ruling], "Appeal fee is already paid.");
		uint256 appealCost = arbitrator.appealCost(disputeId, extraDatas[claim.arbSettingsId]);
		uint256 totalCost = appealCost + ((appealCost * multiplier) / BASIS_POINTS);

		// Take up to the amount necessary to fund the current round at the current costs.
		uint256 contribution = (totalCost - round.paidFees[_ruling]) > msg.value
			? msg.value
			: totalCost - round.paidFees[_ruling];
		emit Contribution(_claimId, lastRoundID, _ruling, msg.sender, contribution);

		round.contributions[msg.sender][_ruling] += contribution;
		round.paidFees[_ruling] += contribution;
		if (round.paidFees[_ruling] >= totalCost) {
			round.feeRewards += round.paidFees[_ruling];
			round.fundedAnswers.push(_ruling);
			round.hasPaid[_ruling] = true;
			emit RulingFunded(_claimId, lastRoundID, _ruling);
		}

		if (round.fundedAnswers.length > 1) {
			// At least two sides are fully funded.
			claim.rounds.push();

			round.feeRewards = round.feeRewards - appealCost;
			arbitrator.appeal{value: appealCost}(disputeId, extraDatas[claim.arbSettingsId]);
		}

		if (contribution < msg.value) payable(msg.sender).send(msg.value - contribution); // Sending extra value back to contributor. It is the user's responsibility to accept ETH.
		return round.hasPaid[_ruling];
	}

	/**
	 * @notice Sends the fee stake rewards and reimbursements proportional to the contributions made to the winner of a dispute. Reimburses contributions if there is no winner.
	 * @param _claimId The ID of the claim.
	 * @param _beneficiary The address to send reward to.
	 * @param _round The round from which to withdraw.
	 * @param _ruling The ruling to request the reward from.
	 * @return reward The withdrawn amount.
	 */
	function withdrawFeesAndRewards(
		uint256 _claimId,
		address payable _beneficiary,
		uint256 _round,
		uint256 _ruling
	) public override returns (uint256 reward) {
		Claim storage claim = claims[uint64(_claimId)];
		Round storage round = claim.rounds[_round];
		require(claim.solvedAt != 0, "Claim not resolved");
		// Allow to reimburse if funding of the round was unsuccessful.
		if (!round.hasPaid[_ruling]) {
			reward = round.contributions[_beneficiary][_ruling];
		} else if (!round.hasPaid[claim.ruling]) {
			// Reimburse unspent fees proportionally if the ultimate winner didn't pay appeal fees fully.
			// Note that if only one side is funded it will become a winner and this part of the condition won't be reached.
			reward = round.fundedAnswers.length > 1
				? (round.contributions[_beneficiary][_ruling] * round.feeRewards) /
					(round.paidFees[round.fundedAnswers[0]] + round.paidFees[round.fundedAnswers[1]])
				: 0;
		} else if (claim.ruling == _ruling) {
			uint256 paidFees = round.paidFees[_ruling];
			// Reward the winner.
			reward = paidFees > 0 ? (round.contributions[_beneficiary][_ruling] * round.feeRewards) / paidFees : 0;
		}

		if (reward != 0) {
			round.contributions[_beneficiary][_ruling] = 0;
			_beneficiary.send(reward); // It is the user's responsibility to accept ETH.
			emit Withdrawal(_claimId, _round, _ruling, _beneficiary, reward);
		}
	}

	/**
	 * @notice Allows to withdraw any rewards or reimbursable fees for all rounds at once.
	 * @dev This function is O(n) where n is the total number of rounds. Arbitration cost of subsequent rounds is `A(n) = 2A(n-1) + 1`.
	 *      So because of this exponential growth of costs, you can assume n is less than 10 at all times.
	 * @param _claimId The ID of the arbitration.
	 * @param _beneficiary The address that made contributions.
	 * @param _contributedTo Answer that received contributions from contributor.
	 */
	function withdrawFeesAndRewardsForAllRounds(
		uint256 _claimId,
		address payable _beneficiary,
		uint256 _contributedTo
	) external override {
		uint256 numberOfRounds = claims[uint64(_claimId)].rounds.length;

		for (uint256 roundNumber = 0; roundNumber < numberOfRounds; roundNumber++) {
			withdrawFeesAndRewards(_claimId, _beneficiary, roundNumber, _contributedTo);
		}
	}

	/**
	 * @notice Returns the sum of withdrawable amount.
	 * @dev This function is O(n) where n is the total number of rounds.
	 * @dev This could exceed the gas limit, therefore this function should be used only as a utility and not be relied upon by other contracts.
	 * @param _claimId The ID of the arbitration.
	 * @param _beneficiary The contributor for which to query.
	 * @param _contributedTo Answer that received contributions from contributor.
	 * @return sum The total amount available to withdraw.
	 */
	function getTotalWithdrawableAmount(
		uint256 _claimId,
		address payable _beneficiary,
		uint256 _contributedTo
	) external view override returns (uint256 sum) {
		if (claims[uint64(_claimId)].solvedAt == 0) return sum;

		uint256 finalAnswer = claims[uint64(_claimId)].ruling;
		uint256 noOfRounds = claims[uint64(_claimId)].rounds.length;
		for (uint256 roundNumber = 0; roundNumber < noOfRounds; roundNumber++) {
			Round storage round = claims[uint64(_claimId)].rounds[roundNumber];

			if (!round.hasPaid[_contributedTo]) {
				// Allow to reimburse if funding was unsuccessful for this answer option.
				sum += round.contributions[_beneficiary][_contributedTo];
			} else if (!round.hasPaid[finalAnswer]) {
				// Reimburse unspent fees proportionally if the ultimate winner didn't pay appeal fees fully.
				// Note that if only one side is funded it will become a winner and this part of the condition won't be reached.
				sum += round.fundedAnswers.length > 1
					? (round.contributions[_beneficiary][_contributedTo] * round.feeRewards) /
						(round.paidFees[round.fundedAnswers[0]] + round.paidFees[round.fundedAnswers[1]])
					: 0;
			} else if (finalAnswer == _contributedTo) {
				uint256 paidFees = round.paidFees[_contributedTo];
				// Reward the winner.
				sum += paidFees > 0
					? (round.contributions[_beneficiary][_contributedTo] * round.feeRewards) / paidFees
					: 0;
			}
		}
	}
}