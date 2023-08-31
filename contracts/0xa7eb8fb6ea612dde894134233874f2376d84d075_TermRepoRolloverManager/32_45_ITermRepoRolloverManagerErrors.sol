//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoRolloverManagerErrors defines all errors emitted by TermRepoRolloverManager.
interface ITermRepoRolloverManagerErrors {
    error AlreadyTermContractPaired();
    error AuctionEndsAfterRepayment();
    error AuctionEndsBeforeMaturity();
    error BorrowerRepurchaseObligationInsufficient();
    error CollateralTokenNotSupported(address invalidCollateralToken);
    error DifferentPurchaseToken(
        address currentPurchaseToken,
        address rolloverPurchaseToken
    );
    error InvalidParameters(string reason);
    error MaturityReached();
    error NoRolloverToCancel();
    error NotTermContract(address invalidAddress);
    error RepurchaseWindowOver();
    error RolloverAddressNotApproved(address invalidAddress);
    error RolloverLockedToAuction();
    error RolloverProcessedToTerm();
    error ZeroBorrowerRepurchaseObligation();
}