// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IBonklerAuction.sol";
import "../interfaces/IBonklerTreasury.sol";
import "../interfaces/ITiny721.sol";

/**
	Thrown when attempting to stage a bid that does not meet minimum requirements.

	@param bidAmount The bid amount that the caller attempted to stage.
*/
error InvalidBidAmount (
	uint256 bidAmount
);

/**
	Thrown when including another staged bid would overfractionalize a Bonkler.

	@param bonklerId The ID of the Bonkler which would overfractionalize.
*/
error CannotOverfractionalize (
	uint256 bonklerId
);

/**
	Thrown when attempting to stage a bid on an old Bonkler.

	@param bonklerId The ID of the Bonkler which the bid was attempted on.
*/
error InvalidBonklerBid (
	uint256 bonklerId
);

/**
	Thrown when attempting to stage a bid while already winning an auction.

	@param bonklerId The ID of the Bonkler which the bid was attempted on.
*/
error AlreadyWinningAuction (
	uint256 bonklerId
);

/**
	Thrown when attempting to withdraw a bid from a settled auction.

	@param bonklerId The ID of the Bonkler which the withdraw was attempted on.
*/
error CannotWithdrawSettledItem (
	uint256 bonklerId
);

/**
	Thrown when attempting to withdraw a bid from a live auction.

	@param bonklerId The ID of the Bonkler which the withdraw was attempted on.
*/
error CannotWithdrawActiveBid (
	uint256 bonklerId
);

/**
	Thrown when unable to withdraw Ether from the contract.
*/
error EtherTransferWasUnsuccessful ();

/**
	Thrown when attempting to settle a won bid on an invalid Bonkler.

	@param bonklerId The ID of the Bonkler which the settle was attempted on.
*/
error CannotSettle (
	uint256 bonklerId
);

/// Thrown when attempting to vote without a valid Bonklet.
error Unauthorized ();

/**
	Thrown when attempting to redeem a Bonklet for an unredeemed Bonkler.

	@param bonklerId The ID of the unredeemed Bonkler.
*/
error CannotClaimUnredeemedBonkler (
	uint256 bonklerId
);

/**
	Thrown when receiving Ether from a caller other than the extended treasury.

	@param sender The address of the unexpected sender.
*/
error SenderNotTreasury (
	address sender
);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A fractionalized bidding system for Bonkler.
	@author Tim Clancy <tim-clancy.eth>
	@custom:version 1.0

	Bonkler is a religious artifact bestowed to us by the Remilia Corporation. 
	This contract allows callers to pool their Ether together to bid for a shared 
	Bonkler. Fractional Bonkler shares are represented as ERC-721 tokens called 
	Bonklets. Fractional holders may vote to redeem or transfer their shared 
	Bonkler.

	@custom:date April 20th, 2023.
*/
contract BonkletBidder is ReentrancyGuard {

	/// The address of the Bonkler auction contract.
	address immutable public BONKLER_AUCTION;

	/// The address of the Bonkler NFT contract.
	address immutable public BONKLER;
	
	/// The address of the extended Bonkler treasury contract.
	address immutable public BONKLER_TREASURY;

	/// The address of the Bonklet NFT contract.
	address immutable public BONKLET;

	/// The minimum bid accepted for joining a Bonkler fractionalization.
	uint256 immutable public BID_MINIMUM;

	/// The maximum number of bidders on a Bonkler.
	uint256 immutable public BIDDER_LIMIT;

	/// The quorum required for conducting a redemption.
	uint256 immutable public REDEMPTION_QUORUM;

	/// A mapping of specific Bonkler IDs to the total Ether staged to bid on it.
	mapping ( uint256 => uint256 ) public stagedTotal;

	/// A mapping of specific Bonkler IDs to a mapping of per-caller staged bids.
	mapping ( uint256 => mapping ( address => uint256 )) public callerStagedBids;

	/**
		This struct defines a set of specific bidders who participated in a Bonkler 
		round.

		@param bidders An array of unique bidder addresses.
		@param didBid A mapping to track whether a particular address has yet bid.
	*/
	struct BidderSet {
		address[] bidders;
		mapping ( address => bool ) didBid;
	}

	/// A mapping of specific Bonkler IDs to bidder sets.
	mapping ( uint256 => BidderSet ) private _bidderSets;

	/// A mapping of Bonkler IDs to whether their receipt has been settled.
	mapping ( uint256 => bool ) public settled;

	/**
		This struct defines relevant data required for tracking the voting powers 
		of a specific Bonklet. This information also impacts the display of 
		metadata.

		@param bonklerId The ID of the corresponding Bonkler that this Bonklet is 
			fractionalizing.
		@param stagedEther The amount of Ether represented by this Bonklet fraction.
	*/
	struct BonkletData {
		uint128 bonklerId;
		uint128 stagedEther;
	}

	/// A mapping of Bonklet token ID to relevant voting-based metadata.
	mapping ( uint256 => BonkletData ) public bonkletData;

	/**
		A mapping of a Bonklet token ID to whether it has voted in favor of Bonkler 
		redemption.
	*/
	mapping ( uint256 => bool ) public redemptionVoted;

	/**
		A mapping from a Bonkler token ID to the number of shares that have voted 
		in favor of redemption.
	*/
	mapping ( uint256 => uint256 ) public redemptionShares;

	/// A mapping of Bonkler IDs to their redeemed shares.
	mapping ( uint256 => uint256 ) public redeemed;

	/**
		A mapping of a Bonklet token ID to whether it has voted in favor of Bonkler 
		transfer to a particular destination address.
	*/
	mapping ( uint256 => mapping ( address => bool )) public transferVoted;

	/**
		A mapping from a Bonkler token ID to the number of shares that have voted 
		in favor of transfer to a particular destination address.
	*/
	mapping ( uint256 => mapping ( address => uint256 )) public transferShares;

	/**
		This event is emitted when a bid is staged.

		@param bidder The address of the caller who created the bid.
		@param bonklerId The Bonkler ID being bid on.
		@param amount The amount of Ether just staged for bidding.
		@param totalAmount The total amount of Ether ready to bid.
	*/
	event BidStaged (
		address indexed bidder,
		uint256 bonklerId,
		uint256 amount,
		uint256 totalAmount
	);

	/**
		This event is emitted when a bid is executed against the Bonkler auction 
		contract.

		@param bidder The address of the caller who created the bid.
		@param bonklerId The Bonkler ID being bid on.
		@param totalAmount The total amount of Ether ready to bid.
	*/
	event BidExecuted (
		address indexed bidder,
		uint256 bonklerId,
		uint256 totalAmount
	);

	/**
		This event is emitted when a failed bid is withdrawn.

		@param bidder The address of the caller who created the bid.
		@param bonklerId The Bonkler ID being bid on.
		@param totalAmount The total amount of Ether withdrawn.
	*/
	event BidWithdrawn (
		address indexed bidder,
		uint256 bonklerId,
		uint256 totalAmount
	);

	/**
		This event is emitted when a won Bonkler is settled.

		@param settler The address of the caller who performs the settling.
		@param bonklerId The Bonkler ID being settled.
	*/
	event Settled (
		address indexed settler,
		uint256 bonklerId
	);

	/**
		This event records when a vote has been placed for redeeming a Bonkler.

		@param voter The address of the voter.
		@param bonklerId The ID of the Bonkler being voted on.
		@param bonkletId The ID of the Bonklet being voted with.
		@param signal Whether or not the voter is in favor.
		@param shares The number of shares this voter has.
	*/
	event RedemptionVote (
		address indexed voter,
		uint256 bonklerId,
		uint256 bonkletId,
		bool signal,
		uint256 shares
	);

	/**
		This event records when a vote for redeeming a Bonkler has been executed.

		@param voter The final voter who executed the redemption.
		@param bonklerId The ID of the Bonkler being redeemed.
		@param bonkletId The ID of the Bonklet which triggered the redemption.
	*/
	event RedemptionExecuted (
		address indexed voter,
		uint256 bonklerId,
		uint256 bonkletId
	);

	/**
		This event records when a caller claims a redeemed portion of a Bonkler 
		using a Bonklet.

		@param claimant The address of the caller who claimed.
		@param bonkletId The ID of the Bonklet which claimed.
		@param reward The Ether rewarded for this claim.
	*/
	event BonkletClaimed (
		address indexed claimant,
		uint256 bonkletId,
		uint256 reward
	);

	/**
		This event records when a vote has been placed for transferring a Bonkler 
		to a particular address.

		@param voter The address of the voter.
		@param bonklerId The ID of the Bonkler being voted on.
		@param bonkletId The ID of the Bonklet being voted with.
		@param destination The destination address of the Bonkler being voted for.
		@param signal Whether or not the voter is in favor.
		@param shares The number of shares this voter has.
	*/
	event TransferVote (
		address indexed voter,
		uint256 bonklerId,
		uint256 bonkletId,
		address destination,
		bool signal,
		uint256 shares
	);

	/**
		This event records when a vote for redeeming a Bonkler has been executed.

		@param voter The final voter who executed the redemption.
		@param bonklerId The ID of the Bonkler being redeemed.
		@param bonkletId The ID of the Bonklet which triggered the redemption.
		@param destination The destination address where the Bonkler was sent.
	*/
	event TransferExecuted (
		address indexed voter,
		uint256 bonklerId,
		uint256 bonkletId,
		address destination
	);

	/**
		Construct a new instance of the Bonklet bid fractionalizer configured with 
		the given immutable contract addresses.

		@param _bonklerAuction The address of the Bonkler auction contract.
		@param _bonkler The address of the Bonkler NFT contract.
		@param _bonklerTreasury The address of the extended Bonkler treasury.
		@param _bonklet The address of the fractional Bonklet NFT contract.
		@param _bidMinimum The minimum bid accepted for fractionalization.
		@param _bidderLimit The maximum number of bidders who may share 
			fractionalization on a first-come, first-serve basis.
		@param _redemptionQuorum The threshold required to reach a quorum for a 
			redemption vote.
	*/
	constructor (
		address _bonklerAuction,
		address _bonkler,
		address _bonklerTreasury,
		address _bonklet,
		uint256 _bidMinimum,
		uint256 _bidderLimit,
		uint256 _redemptionQuorum
	) {
		BONKLER_AUCTION = _bonklerAuction;
		BONKLER = _bonkler;
		BONKLER_TREASURY = _bonklerTreasury;
		BONKLET = _bonklet;
		BID_MINIMUM = _bidMinimum;
		BIDDER_LIMIT = _bidderLimit;
		REDEMPTION_QUORUM = _redemptionQuorum;

		// Approve the extended treasury to handle Bonkler redemption.
		IERC721(BONKLER).setApprovalForAll(BONKLER_TREASURY, true);
	}

	/**
		Stage a bid for submission to the Bonkler auction contract. If the 
		resources for a bid are obtained, one is automatically created.

		@param _bonklerId The ID of the Bonkler to withdraw failed bid Ether for.
		@param _generationHash The generation hash to submit for the Bonkler.
	*/
	function stageBid (
		uint256 _bonklerId,
		uint256 _generationHash
	) external payable nonReentrant {

		// Revert if the provided bid is too small.
		if (msg.value < BID_MINIMUM) {
			revert InvalidBidAmount(msg.value);
		}

		// Check for, and record, whether the current bidder is new.
		BidderSet storage bidderSet = _bidderSets[_bonklerId];
		if (!bidderSet.didBid[msg.sender]) {
			bidderSet.bidders.push(msg.sender);
			bidderSet.didBid[msg.sender] = true;

			// Prevent exceeding the limit on the number of bidders on a Bonkler.
			if (bidderSet.bidders.length > BIDDER_LIMIT) {
				revert CannotOverfractionalize(_bonklerId);
			}
		}

		// Retrieve the current auction details.
		AuctionData memory auction = IBonklerAuction(BONKLER_AUCTION).auctionData();

		// Revert if we are bidding on a not-current Bonkler.
		if (auction.bonklerId != _bonklerId) {
			revert InvalidBonklerBid(_bonklerId);
		}

		// Revert if we are already winning the auction.
		if (auction.bidder == address(this)) {
			revert AlreadyWinningAuction(_bonklerId);
		}

		// Store the current message value against this auction.
		uint256 newTotal;
		unchecked {
			newTotal = stagedTotal[_bonklerId] + msg.value;
			callerStagedBids[_bonklerId][msg.sender] += msg.value;
		}
		stagedTotal[_bonklerId] = newTotal;

		// Emit a bid-staging event.
		emit BidStaged(msg.sender, _bonklerId, msg.value, newTotal);

		// If we have obtained sufficient Ether, emit an event then create a bid.
		if (auction.amount < newTotal) {
			emit BidExecuted(msg.sender, _bonklerId, newTotal);

			// Create the bid by calling out to the Bonkler auction contract.
			IBonklerAuction(BONKLER_AUCTION).createBid{ value: newTotal }(
				_bonklerId,
				_generationHash
			);
		}
	}

	/**
		Permit callers to withdraw embedded Ether for an intended bid if the bid is 
		not active in the current auction and the bid failed.

		@param _bonklerId The ID of the Bonkler to withdraw failed bid Ether for.
	*/
	function withdrawBid (
		uint256 _bonklerId
	) external nonReentrant {

		/*
			Prevent withdrawals if the Bonkler is owned by this contract, or if 
			receipt of the Bonkler has already been settled.
		*/
		if (
			IERC721(BONKLER).ownerOf(_bonklerId) == address(this) || 
			settled[_bonklerId]
		) {
			revert CannotWithdrawSettledItem(_bonklerId);
		}

		// Retrieve the current auction details.
		AuctionData memory auction = IBonklerAuction(BONKLER_AUCTION).auctionData();

		// Revert if attempting to withdraw from the active, unsettled bid.
		if (auction.bonklerId == _bonklerId && !auction.settled) {
			revert CannotWithdrawActiveBid(auction.bonklerId);
		}

		// Track the caller withdrawal.
		uint256 withdrawal = callerStagedBids[_bonklerId][msg.sender];
		if (withdrawal > 0) {
			unchecked {
				stagedTotal[_bonklerId] -= withdrawal;
			}
			callerStagedBids[_bonklerId][msg.sender] = 0;

			// Return the caller their Ether.
			(bool success, ) = (msg.sender).call{ value: withdrawal }("");
			if (!success) {
				revert EtherTransferWasUnsuccessful();
			}

			// Emit an event.
			emit BidWithdrawn(msg.sender, _bonklerId, withdrawal);
		}
	}

	/**
		Allow for Bonklets to be created from victorious auctions.

		@param _bonklerId The ID of the Bonkler to settle.
	*/
	function settle (
		uint256 _bonklerId
	) external nonReentrant {
		
		// Prevent settlement of an unowned or already-settled Bonkler.
		if (
			settled[_bonklerId] ||
			IERC721(BONKLER).ownerOf(_bonklerId) != address(this) 
		) {
			revert CannotSettle(_bonklerId);
		}

		// Mint a Bonklet to every participating bidder given their score.
		uint256 tokenId = ITiny721(BONKLET).totalSupply() + 1;
		address[] memory bidders = _bidderSets[_bonklerId].bidders;
		for (uint256 i; i < bidders.length; ) {
			address bidder = bidders[i];
			ITiny721(BONKLET).mint_Qgo(bidder, 1);

			// Store relevant voting information for each Bonklet.
			unchecked {
				bonkletData[tokenId + i] = BonkletData({
					bonklerId: uint128(_bonklerId),
					stagedEther: uint128(callerStagedBids[_bonklerId][bidder])
				});
				++i;
			}
		}
		settled[_bonklerId] = true;

		// Emit an event.
		emit Settled(msg.sender, _bonklerId);
	}

	/**
		Toggle support for a quorum vote to redeem a Bonkler.

		@param _bonkletId The ID of the Bonklet to vote with.
	*/
	function redeem (
		uint256 _bonkletId
	) external nonReentrant {

		// Only allow Bonklet holders to vote with their own Bonklets.
		if (IERC721(BONKLET).ownerOf(_bonkletId) != msg.sender) {
			revert Unauthorized();
		}

		// If the Bonklet had previously voted, remove its support.
		BonkletData memory bonklet = bonkletData[_bonkletId];
		uint256 bonklerId = bonklet.bonklerId;
		if (redemptionVoted[_bonkletId]) {
			redemptionVoted[_bonkletId] = false;
			unchecked {
				redemptionShares[bonklerId] -= bonklet.stagedEther;
			}

			// Emit an event recording the vote.
			emit RedemptionVote(
				msg.sender,
				bonklerId,
				_bonkletId,
				false,
				bonklet.stagedEther
			);

		// Otherwise, record the Bonklet vote.
		} else {
			redemptionVoted[_bonkletId] = true;
			unchecked {
				redemptionShares[bonklerId] += bonklet.stagedEther;
			}

			// Emit an event recording the vote.
			emit RedemptionVote(
				msg.sender,
				bonklerId,
				_bonkletId,
				true,
				bonklet.stagedEther
			);

			// If redemption quorum is achieved, redeem.
			uint256 power;
			unchecked {
				power = redemptionShares[bonklerId] * 100 / stagedTotal[bonklerId];
			}
			if (power > REDEMPTION_QUORUM) {
				redeemed[bonklerId] = IBonklerTreasury(BONKLER_TREASURY).redeemBonkler(
					bonklerId
				);

				// Emit an event recording execution of the redemption vote.
				emit RedemptionExecuted(
					msg.sender,
					bonklerId,
					_bonkletId
				);
			}
		}
	}

	/**
		This function allows Bonklet holders to claim their share of rewards from a
		redeemed Bonkler. Calling this function requires approving this contract to 
		transfer Bonklets on behalf of the caller. After claiming, the Bonklet is 
		transferred to be held in eternal escrow by this contract.

		@param _bonkletId The ID of the Bonklet to vote with.
	*/
	function claim (
		uint256 _bonkletId
	) external nonReentrant {

		// Only allow Bonklet holders to claim with their own Bonklets.
		if (IERC721(BONKLET).ownerOf(_bonkletId) != msg.sender) {
			revert Unauthorized();
		}

		// Prevent claiming an unredeeemed Bonkler.
		BonkletData memory bonklet = bonkletData[_bonkletId];
		uint256 bonklerId = bonklet.bonklerId;
		if (redeemed[bonklerId] == 0) {
			revert CannotClaimUnredeemedBonkler(bonklerId);
		}

		// Transfer the caller Bonklet to be held in eternal escrow.
		IERC721(BONKLET).transferFrom(
			msg.sender,
			address(this),
			_bonkletId
		);

		// Return the claimant's portion of the redeemed reward.
		uint256 reward;
		unchecked {
			reward = bonklet.stagedEther * redeemed[bonklerId]
				/ stagedTotal[bonklerId];
		}
		(bool success, ) = (msg.sender).call{ value: reward }("");
		if (!success) {
			revert EtherTransferWasUnsuccessful();
		}

		// Emit an event recording this claim.
		emit BonkletClaimed(msg.sender, _bonkletId, reward);
	}

	/**
		Toggle support for a unanimous vote to transfer a Bonkler.

		@param _bonkletId The ID of the Bonklet to vote with.
		@param _destination The destination being voted on for the Bonkler transfer.
	*/
	function transfer (
		uint256 _bonkletId,
		address _destination
	) external nonReentrant {

		// Only allow Bonklet holders to vote with their own Bonklets.
		if (IERC721(BONKLET).ownerOf(_bonkletId) != msg.sender) {
			revert Unauthorized();
		}

		// If the Bonklet had previously voted, remove its support.
		BonkletData memory bonklet = bonkletData[_bonkletId];
		uint256 bonklerId = bonklet.bonklerId;
		if (transferVoted[_bonkletId][_destination]) {
			transferVoted[_bonkletId][_destination] = false;
			unchecked {
				transferShares[bonklerId][_destination] -= bonklet.stagedEther;
			}

			// Emit an event recording the vote.
			emit TransferVote(
				msg.sender,
				bonklerId,
				_bonkletId,
				_destination,
				false,
				bonklet.stagedEther
			);

		// Otherwise, record the Bonklet vote.
		} else {
			transferVoted[_bonkletId][_destination] = true;
			unchecked {
				transferShares[bonklerId][_destination] += bonklet.stagedEther;
			}

			// Emit an event recording the vote.
			emit TransferVote(
				msg.sender,
				bonklerId,
				_bonkletId,
				_destination,
				true,
				bonklet.stagedEther
			);

			// If transfer unanimity is achieved, transfer.
			if (transferShares[bonklerId][_destination] == stagedTotal[bonklerId]) {
				IERC721(BONKLER).transferFrom(
					address(this),
					_destination,
					bonklerId
				);
				
				// Emit an event recording execution of the transfer vote.
				emit TransferExecuted(
					msg.sender,
					bonklerId,
					_bonkletId,
					_destination
				);
			}
		}
	}

	/**
		This function allows the BonkletBidder to receive funds from the extended 
		Bonkler treasury.
	*/
	receive () external payable {
		
		/*
			We do not want anyone getting their Ether stuck in this contract, so we 
			revert if the sender is not the extended Bonkler treasury.
		*/
		if (msg.sender != BONKLER_TREASURY) {
			revert SenderNotTreasury(msg.sender);
		}
	}
}