// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.16;

interface ISimiDAO {
    struct ApprovedDonation {
        string name; // name of the proposal
        uint256 duration; // duration of the proposal in seconds
        string media; // media link of the proposal
        address proposer; // the account that submitted the proposal (can be non-member)
        uint256 paymentRequested; // amount of tokens requested as payment
        uint256 amountRaised; // amount of tokens raised
        uint256 startingTime; // the time in which voting can start for this proposal
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 donors;
        bool exists; // always true once a member has been created
    }

    function isValidForDonation(uint _proposalId) external view returns (bool);

    function getApprovedDonation(uint _proposalId) external view returns (ApprovedDonation memory);

    function receivedDonation(uint _proposalId, uint256 _amount) external;
}