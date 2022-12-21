// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/interface/IEventLogger.sol";

interface IL1EventLogger is IEventLogger {
    function emitClaimEtherForMultipleNftsMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_,
        address beneficiary_
    ) external;

    function emitClaimEtherMessageSent(
        address canonicalNft_,
        uint256 tokenId_,
        address beneficiary_
    ) external;

    function emitMarkReplicasAsAuthenticMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external;

    function emitMarkReplicasAsAuthenticMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external;
}