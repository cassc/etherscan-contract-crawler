// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "../library/NetworkLoanData.sol";

interface INetworkLoan {
    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    event LoanOfferCreated(
        uint256 _loanId,
        NetworkLoanData.LoanDetails _loanDetails
    );

    event LoanOfferAdjusted(
        uint256 _loanId,
        NetworkLoanData.LoanDetails _loanDetails
    );

    event LoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancel(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event FullLoanPaybacked(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event PartialLoanPaybacked(
        uint256 loanId,
        uint256 paybackAmount,
        address _borrower
    );

    event AutoLiquidated(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event LiquidatedCollaterals(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );

    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
    event LTVPercentageUpdated(uint256 ltvPercentage);
}