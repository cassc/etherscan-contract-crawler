// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Participation 
    @author iMe Lab
    @notice Library for working with centralized participation
 */
library Participation {
    string internal constant SIGNED_MSG_PREFIX =
        "\x19Ethereum Signed Message:\n32";
    error ParticipationNotSigned();

    struct Participant {
        address addr;
        bytes32 name;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function requireSigned(
        Participant memory participant,
        Signature memory sig,
        address issuer,
        address trustedSigner
    ) internal pure {
        bytes32 digest = _digestOf(participant, issuer);
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);

        if (signer != trustedSigner) revert ParticipationNotSigned();
    }

    function requireSigned(
        Participant[] memory participants,
        Signature memory sig,
        address issuer,
        address trustedSigner
    ) internal pure {
        bytes32 digest = _digestOf(participants, issuer);
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);

        if (signer != trustedSigner) revert ParticipationNotSigned();
    }

    function _digestOf(
        Participant memory participant,
        address issuer
    ) private pure returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(participant.addr, participant.name, issuer)
        );

        return keccak256(abi.encodePacked(SIGNED_MSG_PREFIX, message));
    }

    function _digestOf(
        Participant[] memory participants,
        address issuer
    ) private pure returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(issuer, "Waterfall"));

        for (uint i = 0; i < participants.length; i++) {
            message = keccak256(
                abi.encodePacked(
                    participants[i].name,
                    message,
                    participants[i].addr
                )
            );
        }

        return keccak256(abi.encodePacked(SIGNED_MSG_PREFIX, message));
    }
}