// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
interface IVotesLite {
    // an account's current voting power
    function getVotes(address account) external view returns (uint256);
    // a weighting factor used to convert token holdings to voting power (in basis points)
    function getVoteWeightBips(address account) external view returns (uint256);
}