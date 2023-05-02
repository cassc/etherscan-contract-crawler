// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISignatures.sol";

interface IOfferController is ISignatures {
    event OfferCancelled(address indexed user, uint256 salt);
    event NonceIncremented(address indexed user, uint256 newNonce);

    function cancelOffer(uint256 salt) external;

    function cancelOffers(uint256[] calldata salts) external;

    function incrementNonce() external;

    /* Admin */
    function setOracle(address oracle, bool approved) external;

    function setBlockRange(uint256 blockRange) external;
}