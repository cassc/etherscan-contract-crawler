// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
interface IVotesLite {
    // an account's current voting power
    function getVotes(address account) external view returns (uint256);
    // an total current voting power
    function getTotalVotes() external view returns (uint256);
    // a weighting factor used to convert token holdings to voting power (eg in basis points)
    function getVoteFactor(address account) external view returns (uint256);
}