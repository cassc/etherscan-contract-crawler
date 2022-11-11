//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error OnlyOwnerCanDepositToken();
    error InvalidIpfsMultiHash();
    error NothingToClaim();
    error InvalidLength();
    error InvalidAmount();
    error FailedToSendEther();
}