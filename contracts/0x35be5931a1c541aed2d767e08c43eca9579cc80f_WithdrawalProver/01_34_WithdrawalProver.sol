/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./Prover.sol";
import "./StateVerifier.sol";
import "../lib/FactSigs.sol";

/**
 * @title WithdrawalProver
 * @author Theori, Inc.
 * @notice WithdrawalProver proves valid withdrawals at some particular block.
 */
contract WithdrawalProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct WithdrawalProof {
        uint256 idx;
        bytes withdrawalProof;
        bytes header;
        bytes blockProof;
    }

    function parseWithdrawalProof(bytes calldata proof)
        internal
        pure
        returns (WithdrawalProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded WithdrawalProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        WithdrawalProof calldata proof = parseWithdrawalProof(encodedProof);
        (
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.WithdrawalData memory withdrawal
        ) = verifyWithdrawalAtBlock(
                proof.idx,
                proof.withdrawalProof,
                proof.header,
                proof.blockProof
            );

        bytes memory data = abi.encode(withdrawal);
        return
            Fact(
                withdrawal.Address,
                FactSigs.withdrawalFactSig(head.Number, withdrawal.Index),
                data
            );
    }
}