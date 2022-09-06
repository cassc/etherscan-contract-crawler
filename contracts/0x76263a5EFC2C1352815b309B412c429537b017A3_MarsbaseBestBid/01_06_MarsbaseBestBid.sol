pragma solidity >=0.8.0 <0.9.0;

import "./MarsBaseCommon.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

// import "hardhat/console.sol";

interface IMarsbaseBestBid
{
	struct BBBid
	{
		uint256 offerId;
		uint256 bidIdx;

		address bobAddress;

		address tokenBob;
		uint256 amountBob;
		// uint256 depositedBob;
	}
	struct BBOffer
	{
		bool active;
		uint256 id;

		address aliceAddress;

		BBOfferParams params;

		uint256 totalBidsCount;
		uint256 activeBidsCount;
	}
	struct BBOfferParams
	{
		address tokenAlice;
		uint256 amountAlice;
		// uint256 depositedAlice;

		address[] tokensBob;

		uint256 feeAlice;
		uint256 feeBob;

		// uint256 deadline;
	}

	event OfferCreated(
		uint256 indexed id,
        address indexed aliceAddress,
		address indexed tokenAlice,
        BBOfferParams params
	);
	event BidCreated(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);
	enum OfferCloseReason {
		Success,
		CancelledBySeller,
		ContractMigrated
	}
	enum BidCancelReason {
		OfferClosed,
		CancelledByBidder,
		ContractMigrated
	}
	event OfferClosed(
		uint256 indexed id,
		address indexed aliceAddress,
		OfferCloseReason indexed reason,
		BBOffer offer
	);
	event BidAccepted(
		uint256 indexed id,
		address indexed aliceAddress,
		uint256 aliceReceivedTotal,
		uint256 aliceFeeTotal,
		uint256 bobReceivedTotal,
		uint256 bobFeeTotal,
		BBOffer offer,
		BBBid bid
	);
	event BidCancelled(
		uint256 indexed offerId,
		address indexed bobAddress,
		address indexed tokenBob,
		BidCancelReason reason,
		uint256 bidIdx,
		bytes32 bidId,
		BBBid bid
	);

	function createOffer(BBOfferParams calldata offer) external payable;
	function createBid(uint256 offerId, address tokenBob, uint256 amountBob) external payable;
	function acceptBid(uint256 offerId, uint256 bidIdx) external;
	function cancelBid(uint256 offerId, uint256 bidIdx) external;
	function cancelOffer(uint256 offerId) external;

	function getActiveOffers() external returns (BBOffer[] memory);
}
contract MarsbaseBestBid is IMarsbaseBestBid
{
	address public owner;

	uint256 public nextOfferId = 0;
	uint256 public activeOffersCount = 0;

	uint256 public minimumFee = 0;

	address public commissionWallet;
	// address public commissionExchanger;

	bool public locked = false;

	mapping(uint256 => BBOffer) public offers;
	mapping(bytes32 => BBBid) public offerBids;

	constructor(uint256 startOfferId)
	{
		owner = msg.sender;
		commissionWallet = msg.sender;
		nextOfferId = startOfferId;
	}

	// onlyOwner modifier
	modifier onlyOwner {
		require(msg.sender == owner, "403");
		_;
	}
	modifier unlocked {
		require(!locked, "409");
		_;
	}
	function setCommissionAddress(address wallet) onlyOwner public
	{
		commissionWallet = wallet;
	}
	function setMinimumFee(uint256 _minimumFee) onlyOwner public
	{
		minimumFee = _minimumFee;
	}
	function changeOwner(address newOwner) onlyOwner public
	{
		owner = newOwner;
	}

	function getActiveOffers() external view returns (BBOffer[] memory)
	{
		BBOffer[] memory activeOffers = new BBOffer[](activeOffersCount);
		uint256 i = 0;
		for (uint256 offerId = 0; offerId < nextOfferId; offerId++)
		{
			if (offers[offerId].active)
			{
				activeOffers[i] = offers[offerId];
				i++;
			}
		}
		return activeOffers;
	}
	function getBidId(uint256 offerId, uint256 bidIdx) public pure returns (bytes32 bidId)
	{
		return keccak256(abi.encode(offerId, bidIdx));
	}
	function getActiveBidsForOffer(uint256 offerId) external view returns (BBBid[] memory)
	{
		BBOffer memory offer = offers[offerId];
		BBBid[] memory bids = new BBBid[](offer.activeBidsCount);
		uint256 i = 0;
		for (uint256 bidIdx = 0; bidIdx < offer.totalBidsCount; bidIdx++)
		{
			if (offerBids[getBidId(offerId, bidIdx)].amountBob > 0)
			{
				bids[i] = offerBids[getBidId(offerId, bidIdx)];
				i++;
			}
		}
		return bids;
	}
	function getOffer(uint256 offerId) public view returns (BBOffer memory)
	{
		return offers[offerId];
	}

	function createOffer(BBOfferParams calldata offer) public payable unlocked
	{
		// basic checks
		require(offer.amountAlice > 0, "400-AAL");
		require(offer.tokensBob.length > 0, "400-BE");
		// require(offer.depositedAlice > offer.amountAlice / 10, "400-DAL");
		require(offer.feeAlice + offer.feeBob >= minimumFee, "400-FL");

		// transfer deposit
		if (offer.tokenAlice == address(0))
			require(offer.amountAlice == msg.value, "402-E");
		else
			IERC20(offer.tokenAlice).safeTransferFrom(msg.sender, address(this), offer.amountAlice);

		uint256 offerId = nextOfferId++;
		activeOffersCount++;

		offers[offerId] = BBOffer({
			active: true,
			id: offerId,
			aliceAddress: msg.sender,
			params: offer,
			totalBidsCount: 0,
			activeBidsCount: 0
		});

		emit OfferCreated({
			id: offerId,
			aliceAddress: msg.sender,
			tokenAlice: offer.tokenAlice,
			params: offer
		});
	}
	function createBid(uint256 offerId, address tokenBob, uint256 amountBob) public payable unlocked
	{
		// basic checks
		require(amountBob > 0, "400-ABL");
		require(offers[offerId].active, "400-OI");

		//
		// this check is temporary disabled to make bidding with unknown tokens possible
		// frontend is expected to filter out garbage if needed
		//
		// { // split to block to prevent solidity stack issues
		// 	bool accepted = false;
		// 	address[] memory tokensBob = offers[offerId].params.tokensBob;
		// 	for (uint256 i = 0; i < tokensBob.length; i++)
		// 	{
		// 		if (tokensBob[i] == tokenBob)
		// 		{
		// 			accepted = true;
		// 			break;
		// 		}
		// 	}
		// 	require(accepted, "404-TBI"); // Token Bob is Incorrect
		// }

		// transfer deposit
		if (tokenBob == address(0))
			require(amountBob == msg.value, "402-E");
		else
			IERC20(tokenBob).safeTransferFrom(msg.sender, address(this), amountBob);

		uint256 bidIdx = offers[offerId].totalBidsCount++;
		bytes32 bidId = getBidId(offerId, bidIdx);
		offers[offerId].activeBidsCount++;
		
		offerBids[bidId] = BBBid({
			offerId: offerId,
			bidIdx: bidIdx,
			bobAddress: msg.sender,
			tokenBob: tokenBob,
			amountBob: amountBob
			// depositedBob: amountBob
		});

		emit BidCreated({
			offerId: offerId,
			bobAddress: msg.sender,
			tokenBob: tokenBob,
			bidIdx: bidIdx,
			bidId: bidId,
			bid: offerBids[bidId]
		});
	}
	function sendEth(address to, uint256 amount) private
	{
		(bool success, ) = to.call{value: amount, gas: 30000}("");
		require(success, "404-C1");
	}
	function cancelBid(uint256 offerId, uint256 bidIdx) public unlocked
	{
		require(offers[offerId].active, "400-OI");

		bytes32 bidId = getBidId(offerId, bidIdx);

		require(offerBids[bidId].amountBob > 0, "400-BI");
		require(offerBids[bidId].bobAddress == msg.sender, "403-BI");

		_cancelBid(offerId, bidIdx, bidId, BidCancelReason.CancelledByBidder);
	}
	function _cancelBid(uint256 offerId, uint256 bidIdx, bytes32 bidId, BidCancelReason reason) private
	{
		BBBid memory bid = offerBids[bidId];
		
		// disable bid
		delete offerBids[bidId];

		offers[offerId].activeBidsCount--;

		// transfer deposit back
		if (bid.tokenBob == address(0))
			sendEth(bid.bobAddress, bid.amountBob);
		else
			IERC20(bid.tokenBob).safeTransfer(bid.bobAddress, bid.amountBob);
		
		emit BidCancelled({
			offerId: offerId,
			bobAddress: bid.bobAddress,
			tokenBob: bid.tokenBob,
			bidIdx: bidIdx,
			bidId: bidId,
			reason: reason,
			bid: bid
		});
	}
	function _cancelAllBids(uint256 offerId, BidCancelReason reason) private
	{
		uint256 length = offers[offerId].totalBidsCount;
		for (uint256 bidIdx = 0; bidIdx < length; bidIdx++)
		{
			bytes32 bidId = getBidId(offerId, bidIdx);
			if (offerBids[bidId].amountBob > 0)
			{
				_cancelBid(offerId, bidIdx, bidId, reason);
			}
		}
	}
	
	uint256 constant MAX_UINT256 = type(uint256).max;
	// max safe uint256 constant that can be calculated for 1e6 fee
	uint256 constant MAX_SAFE_TARGET_AMOUNT = MAX_UINT256 / (1e6);

	function afterFee(uint256 amountBeforeFee, uint256 feePercent) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		if (feePercent == 0)
			return (amountBeforeFee, 0);
		
		return _afterFee(amountBeforeFee, feePercent, 1e5, MAX_SAFE_TARGET_AMOUNT);
	}
	function _afterFee(uint256 amountBeforeFee, uint256 feePercent, uint256 scale, uint256 safeAmount) public pure returns (uint256 amountAfterFee, uint256 fee)
	{
		if (feePercent >= scale)
			return (0, amountBeforeFee);

		if (amountBeforeFee < safeAmount)
			fee = (amountBeforeFee * feePercent) / scale;
		else
			fee = (amountBeforeFee / scale) * feePercent;

		amountAfterFee = amountBeforeFee - fee;
		return (amountAfterFee, fee);
	}

	function _sendTokensAfterFeeFrom(
		address token,
		uint256 amount,
		address from,
		address to,
		uint256 feePercent
	) private returns (uint256 /* amountAfterFee */, uint256 /* fee */)
	{
		if (commissionWallet == address(0))
			feePercent = 0;

		(uint256 amountAfterFee, uint256 fee) = afterFee(amount, feePercent);

		// send tokens to receiver
		if (from == address(this))
			IERC20(token).safeTransfer(to, amountAfterFee);
		else
			IERC20(token).safeTransferFrom(from, to, amountAfterFee);

		if (fee > 0)
		{
			// send fee to commission wallet
			if (from == address(this))
				IERC20(token).safeTransfer(commissionWallet, fee);
			else
				IERC20(token).safeTransferFrom(from, commissionWallet, fee);
		}
		return (amountAfterFee, fee);
	}
	function _sendEthAfterFee(
		uint256 amount,
		address to,
		uint256 feePercent
	) private returns (uint256 /* amountAfterFee */, uint256 /* fee */)
	{
		if (commissionWallet == address(0))
			feePercent = 0;
		
		(uint256 amountAfterFee, uint256 fee) = afterFee(amount, feePercent);

		sendEth(to, amountAfterFee);

		if (fee > 0)
		{
			// send fee to commission wallet
			sendEth(commissionWallet, fee);
		}
		return (amountAfterFee, fee);
	}

	function _acceptBid(BBOffer memory offer, BBBid memory bid) private
	{
		uint256 aliceReceivedTotal;
		uint256 aliceFeeTotal;
		uint256 bobReceivedTotal;
		uint256 bobFeeTotal;

		// send $BOB tokens to Alice
		if (bid.tokenBob == address(0))
			(bobReceivedTotal, bobFeeTotal) = _sendEthAfterFee(bid.amountBob, offer.aliceAddress, offer.params.feeAlice);
		else
			(bobReceivedTotal, bobFeeTotal) = _sendTokensAfterFeeFrom(bid.tokenBob, bid.amountBob, address(this), offer.aliceAddress, offer.params.feeAlice);
		
		// send $ALICE tokens to Bob
		if (offer.params.tokenAlice == address(0))
			(aliceReceivedTotal, aliceFeeTotal) = _sendEthAfterFee(offer.params.amountAlice, bid.bobAddress, offer.params.feeBob);
		else
			(aliceReceivedTotal, aliceFeeTotal) = _sendTokensAfterFeeFrom(offer.params.tokenAlice, offer.params.amountAlice, address(this), bid.bobAddress, offer.params.feeBob);

		// emit accept event
		emit BidAccepted({
			id: offer.id,
			aliceAddress: offer.aliceAddress,
			aliceReceivedTotal: aliceReceivedTotal,
			aliceFeeTotal: aliceFeeTotal,
			bobReceivedTotal: bobReceivedTotal,
			bobFeeTotal: bobFeeTotal,
			offer: offer,
			bid: bid
		});
	}
	function acceptBid(uint256 offerId, uint256 bidIdx) public unlocked
	{
		// basic checks
		require(offers[offerId].active, "400-OI");
		require(offers[offerId].aliceAddress == msg.sender, "403-AI");

		BBOffer memory offer = offers[offerId];
		// get bid
		BBBid memory bid = offerBids[getBidId(offerId, bidIdx)];
		require(bid.amountBob > 0, "400-BI");

		offers[offerId].active = false;
		delete offerBids[getBidId(offerId, bidIdx)];

		_acceptBid(offer, bid);

		// cancel all other bids
		_cancelAllBids(offerId, BidCancelReason.OfferClosed);
		
		// destroy offer
		delete offers[offerId];
		activeOffersCount--;

		// emit offer closed event
		emit OfferClosed({
			id: offerId,
			aliceAddress: offer.aliceAddress,
			reason: OfferCloseReason.Success,
			offer: offer
		});
	}
	function cancelOffer(uint256 offerId) public unlocked
	{
		// basic checks
		require(offers[offerId].active, "400-OI");
		require(offers[offerId].aliceAddress == msg.sender, "403-AI");
		
		_cancelOffer(offerId, BidCancelReason.OfferClosed, OfferCloseReason.CancelledBySeller);
	}
	function _cancelOffer(uint256 offerId, BidCancelReason bidReason, OfferCloseReason offerReason) private
	{
		offers[offerId].active = false;

		BBOffer memory offer = offers[offerId];
		
		// cancel all other bids
		_cancelAllBids(offerId, bidReason);

		// return $ALICE tokens to Alice
		if (offer.params.tokenAlice == address(0))
			sendEth(offer.aliceAddress, offer.params.amountAlice);
		else
			IERC20(offer.params.tokenAlice).safeTransfer(offer.aliceAddress, offer.params.amountAlice);
		
		delete offers[offerId];
		activeOffersCount--;
		
		// emit offer closed event
		emit OfferClosed({
			id: offerId,
			aliceAddress: offers[offerId].aliceAddress,
			reason: offerReason,
			offer: offer
		});
	}
	function lockContract() onlyOwner public
	{
		locked = true;
	}
	function cancelBids(uint256 offerId, uint256 from, uint256 to) onlyOwner public payable
	{
		for (uint256 bidIdx = from; bidIdx < to; bidIdx++)
		{
			bytes32 bidId = getBidId(offerId, bidIdx);
			if (offerBids[bidId].amountBob > 0)
			{
				_cancelBid(offerId, bidIdx, bidId, BidCancelReason.ContractMigrated);
			}
		}
	}
	function cancelOffers(uint256 from, uint256 to) onlyOwner public payable
	{
		for (uint256 offerId = from; offerId < to; offerId++)
		{
			BBOffer memory offer = offers[offerId];
			if (offer.active)
			{
				_cancelOffer(offerId, BidCancelReason.ContractMigrated, OfferCloseReason.ContractMigrated);
			}
		}
	}
}