// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface ICollectionContractInitializer {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractMetaHash_,
        address contractOwner_,
        address trustedProxy_,
        address royaltyRecipient_,
        address[] memory payees,
        uint256[] memory shares_
    ) external;
}