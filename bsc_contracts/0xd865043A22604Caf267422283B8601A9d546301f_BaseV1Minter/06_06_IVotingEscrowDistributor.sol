// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVotingEscrowDistributor {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}