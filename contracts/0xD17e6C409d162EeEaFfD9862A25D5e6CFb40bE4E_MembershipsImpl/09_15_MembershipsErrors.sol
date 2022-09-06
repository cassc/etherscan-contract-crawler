// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface MembershipsErrors {
	error ErrorME01InvalidFee(uint256 minRollFee, uint256 maxFee);
	error ErrorME02TokenNotAllowed();
	error ErrorME03NotEnoughTokens();
	error ErrorME04NotEnoughPhases();
	error ErrorME05OnlyOwnerAllowed();
	error ErrorME06ScheduleDoesNotExists();
	error ErrorME07ScheduleRevoked();
	error ErrorME08ScheduleNotActive();
	error ErrorME09ScheduleNotFinished();
	error ErrorME10ActionAllowlisted();
	error ErrorME11TransferError();
	error ErrorME12IndexOutOfBounds();
	error ErrorME13InvalidAddress();
	error ErrorME14BetaPeriodAlreadyFinish();
	error ErrorME15InvalidDate();
	error ErrorME16InvalidDuration();
	error ErrorME17InvalidPrice();
	error ErrorME18LotArrayLengthMismatch();
	error ErrorME19NotEnoughEth();
	error ErrorME20InvalidReferral();
	error ErrorME21InvalidReferralFee();
	error ErrorME22MaxBuyPerWalletExceeded();
	error ErrorME23TotalClaimedError();
	error ErrorME24InvalidProof();
	error ErrorME25ScheduleNotFinishedOrSoldOut();
	error ErrorME26OnlyMembershipsImpl();
	error ErrorME27TotalAmountExceeded();
	error ErrorME28InvalidAmount();
	error ErrorME29InvalidMaxBuyPerWallet();
}