// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../library/NftLoanData.sol";

interface INftMarket {
    event LoanOfferCreatedNFT(
        uint256 _loanId,
        NftLoanData.LoanDetailsNFT _loanDetailsNFT
    );

    event NFTLoanOfferActivated(
        uint256 nftLoanId,
        address _lender,
        uint256 _loanAmount,
        uint256 _termsLengthInDays,
        uint256 _APYOffer,
        address[] stakedCollateralNFTsAddress,
        uint256[] stakedCollateralNFTId,
        uint256[] stakedNFTPrice,
        NftLoanData.LoanType _loanType,
        bool _isPrivate,
        address _borrowStableCoin
    );

    event NFTLoanOfferAdjusted(
        uint256 _loanId,
        NftLoanData.LoanDetailsNFT _loanDetailsNFT
    );

    event LoanOfferCancelNFT(
        uint256 nftloanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event NFTLoanPaybacked(
        uint256 nftLoanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event AutoLiquidatedNFT(
        uint256 nftLoanId,
        NftLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
}