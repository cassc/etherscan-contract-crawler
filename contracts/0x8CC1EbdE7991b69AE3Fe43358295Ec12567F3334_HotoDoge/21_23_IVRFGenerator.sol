// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

uint256 constant FOEVER = type(uint256).max;
address constant ZERO = 0x0000000000000000000000000000000000000000;

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

interface IVRFGenerator {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 numWords)
        external
        returns (uint256 requestId);

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords);

    function shuffle(uint256 size, uint256 entropy)
        external
        pure
        returns (uint256[] memory);

    function shuffle16(uint16 size, uint256 entropy)
        external
        pure
        returns (uint16[] memory);
}