// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITokenMarketRegistry {
    /**
    @dev function that will get Total Earned APY fee of the loan amount in borrower
     */
    function getAPYFee(
        uint256 _loanAmountInBorrowed,
        uint256 _apyOffer,
        uint256 _termsLengthInDays
    ) external returns (uint256);

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLoanActivateLimit() external view returns (uint256);

    function getLTVPercentage() external view returns (uint256);

    function isWhitelistedForActivation(address) external returns (bool);

    function isSuperAdminAccess(address) external returns (bool);

    function isTokenApproved(address) external returns (bool);

    function isTokenEnabledForCreateLoan(address) external returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function isStableApproved(address _stable) external view returns (bool);

    function getOneInchAggregator() external view returns (address);

    function getMinLoanAmountAllowed() external view returns (uint256);
}