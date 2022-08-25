// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './IOpenSkyBespokeMarket.sol';
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeDataProvider {
    struct LoanDataUI {
        // same as  BespokeTypes.LoanData
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        address currency;
        uint40 borrowDuration;
        uint40 borrowBegin;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        address lender;
        BespokeTypes.LoanStatus status;
        // extra fields
        uint256 loanId;
        uint256 borrowBalance;
        uint256 penalty;
        uint256 borrowInterest;
    }

    function getLoanData(uint256 loanId) external view returns (LoanDataUI memory);
}