// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IL1EventLogger.sol";
import "./interface/IL1EventLoggerEvents.sol";
import "../shared/EventLogger.sol";

contract L1EventLogger is EventLogger, IL1EventLogger, IL1EventLoggerEvents {
    function emitClaimEtherForMultipleNftsMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_,
        address beneficiary_
    ) external {
        emit ClaimEtherForMultipleNftsMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_,
            beneficiary_
        );
    }

    function emitClaimEtherMessageSent(
        address canonicalNft_,
        uint256 tokenId_,
        address beneficiary_
    ) external {
        emit ClaimEtherMessageSent(
            msg.sender,
            canonicalNft_,
            tokenId_,
            beneficiary_
        );
    }

    function emitMarkReplicasAsAuthenticMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external {
        emit MarkReplicasAsAuthenticMessageSent(
            msg.sender,
            canonicalNft_,
            tokenId_
        );
    }

    function emitMarkReplicasAsAuthenticMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external {
        emit MarkReplicasAsAuthenticMultipleMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_
        );
    }

    function emitBurnReplicasAndDisableRemintsMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external {
        emit BurnReplicasAndDisableRemintsMessageSent(
            msg.sender,
            canonicalNft_,
            tokenId_
        );
    }

    function emitBurnReplicasAndDisableRemintsMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external {
        emit BurnReplicasAndDisableRemintsMultipleMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_
        );
    }

    function emitEnableRemintsMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external {
        emit EnableRemintsMessageSent(msg.sender, canonicalNft_, tokenId_);
    }

    function emitEnableRemintsMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external {
        emit EnableRemintsMultipleMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_
        );
    }

    function emitDisableRemintsMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external {
        emit DisableRemintsMessageSent(msg.sender, canonicalNft_, tokenId_);
    }

    function emitDisableRemintsMultipleMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_
    ) external {
        emit DisableRemintsMultipleMessageSent(
            msg.sender,
            canonicalNftsHash_,
            tokenIdsHash_
        );
    }
}