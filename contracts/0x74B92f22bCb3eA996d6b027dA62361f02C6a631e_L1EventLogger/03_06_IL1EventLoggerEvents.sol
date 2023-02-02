// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/interface/IEventLoggerEvents.sol";

interface IL1EventLoggerEvents is IEventLoggerEvents {
    event ClaimEtherForMultipleNftsMessageSent(
        address indexed l1TokenClaimBridge,
        bytes32 canonicalNftsHash,
        bytes32 tokenIdsHash,
        address indexed beneficiary
    );

    event MarkReplicasAsAuthenticMessageSent(
        address indexed l1TokenClaimBridge,
        address indexed canonicalNft,
        uint256 tokenId
    );
}