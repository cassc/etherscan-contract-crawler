// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEscrowContract {
 
 /**
     * Started Escrow mechanism
     * 
     * @param participants array of participants (one of complex arrays participants/tokens/minimums)
     * @param tokens array of tokens (one of complex arrays participants/tokens/minimums)
     * @param minimums array of minimums (one of complex arrays participants/tokens/minimums)
     * @param duration duration of escrow in seconds. will start since locked up to expire
     * @param quorumCount count of participants (which deposit own minimum). After last will initiate locked up
     * @param swapFrom array of participants which resources swap from
     * @param swapTo array of participants which resources swap to
     * @param swapBackAfterEscrow if true, then: if withdraw is called after lock expired, and boxes still contain something, then SWAP BACK (swapTo->swapFrom) left resources
     */
    function init(
        address[] memory participants,
        address[] memory tokens,
        uint256[] memory minimums,
        uint256 duration,
        uint256 quorumCount,
        address[] memory swapFrom,
        address[] memory swapTo,
        bool swapBackAfterEscrow,
        address costManager,
        address producedBy

    ) external;
       
}