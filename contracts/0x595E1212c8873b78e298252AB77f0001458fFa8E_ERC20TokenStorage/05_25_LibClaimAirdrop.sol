// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { LibEIP712 } from './LibEIP712.sol';
import { LibSignature } from './LibSignature.sol';

library LibClaimAirdrop {
    bytes32 constant AIRDROP_CLAIM_TYPEHASH =
        keccak256(
            'ERC20Claim(address recipient,uint256 claimAmountAirdrop,uint256 claimAmountReferral1,uint256 claimAmountReferral2,uint256 claimAmountReferral3,bytes4 airdropId,uint256 lastClaimNonce,uint256 claimNonce)'
        );

    function hashClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    AIRDROP_CLAIM_TYPEHASH,
                    recipient,
                    claimAmountAirdrop,
                    claimAmountReferral1,
                    claimAmountReferral2,
                    claimAmountReferral3,
                    airdropId,
                    lastClaimNonce,
                    claimNonce
                )
            );
    }

    function validateClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes memory airdropServiceSignature,
        address verifyingContractProxy,
        address airdropService
    ) internal pure {
        // Generate EIP712 hashStruct of airdropClaim
        bytes32 hashStruct = hashClaim(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce
        );
        // Verify claim EIP712 hashStruct signature
        if (
            LibSignature.recover(
                LibEIP712.hashEIP712Message(hashStruct, verifyingContractProxy),
                airdropServiceSignature
            ) != airdropService
        ) {
            revert('LibClaimAirdrop: EIP-712 airdrop service signature verification error');
        }
    }
}