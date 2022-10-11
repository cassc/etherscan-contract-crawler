// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILoanDeployer {

    function createLoan(
        address _owner,
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _duration,
        uint64 _paymentPeriod,
        uint8 _interestRate,
        address _teamWallet
    ) external returns (address loan);
}