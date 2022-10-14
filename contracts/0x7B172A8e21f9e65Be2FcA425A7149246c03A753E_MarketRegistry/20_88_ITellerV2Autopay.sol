// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITellerV2Autopay {
    function setAutoPayEnabled(uint256 _bidId, bool _autoPayEnabled) external;

    function autoPayLoanMinimum(uint256 _bidId) external;
}