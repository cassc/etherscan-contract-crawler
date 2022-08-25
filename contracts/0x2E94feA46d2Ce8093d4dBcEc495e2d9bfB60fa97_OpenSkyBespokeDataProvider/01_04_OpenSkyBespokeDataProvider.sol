// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './interfaces/IOpenSkyBespokeMarket.sol';
import './interfaces/IOpenSkyBespokeDataProvider.sol';
import './libraries/BespokeTypes.sol';

/*
 *  a helper contract to aggregate data for front-end
 */
contract OpenSkyBespokeDataProvider is  IOpenSkyBespokeDataProvider{
    IOpenSkyBespokeMarket public immutable MARKET;

    constructor(IOpenSkyBespokeMarket MARKET_) {
        MARKET = MARKET_;
    }

    function getLoanData(uint256 loanId) external view override returns (LoanDataUI memory) {
        BespokeTypes.LoanData memory loan = MARKET.getLoanData(loanId);
        
        return
            LoanDataUI({
                reserveId: loan.reserveId,
                nftAddress: loan.nftAddress,
                tokenId: loan.tokenId,
                tokenAmount: loan.tokenAmount,
                borrower: loan.borrower,
                amount:loan.amount,
                borrowRate: loan.borrowRate,
                interestPerSecond: loan.interestPerSecond,
                currency: loan.currency,
                borrowDuration: loan.borrowDuration,
                borrowBegin: loan.borrowBegin,
                borrowOverdueTime: loan.borrowOverdueTime,
                liquidatableTime: loan.liquidatableTime,
                lender: loan.lender,
                status: loan.status,
                // extra
                loanId: loanId,
                borrowBalance: MARKET.getBorrowBalance(loanId),
                penalty: MARKET.getPenalty(loanId),
                borrowInterest:MARKET.getBorrowInterest(loanId)
            });
    }
}