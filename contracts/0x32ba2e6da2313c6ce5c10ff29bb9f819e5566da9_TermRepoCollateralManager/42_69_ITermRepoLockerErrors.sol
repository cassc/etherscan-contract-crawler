//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoLockerErrors defines all errors emitted by TermRepoLocker.
interface ITermRepoLockerErrors {
    error ERC20TransferFailed();
    error TermRepoLockerTransfersPaused();
}