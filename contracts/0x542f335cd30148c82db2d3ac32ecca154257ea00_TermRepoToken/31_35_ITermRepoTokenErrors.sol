//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoTokenErrors defines all errors emitted by Term Repo Token.
interface ITermRepoTokenErrors {
    error AlreadyTermContractPaired();
    error TermRepoTokenMintingPaused();
    error TermRepoTokenBurningPaused();
    error MintExposureCapExceeded();
}