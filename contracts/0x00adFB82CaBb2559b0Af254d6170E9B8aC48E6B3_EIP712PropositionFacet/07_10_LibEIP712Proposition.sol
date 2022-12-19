//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";
import {LibEIP712Transaction} from "./LibEIP712Transaction.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Proposition` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Proposition {
    bytes32 internal constant _PROPOSITION_TYPEHASH =
        keccak256(
            "Proposition(uint256 endsAt,Transaction tx,bytes32 relevantHash)Transaction(address to,uint256 value,bytes data)"
        );

    function _verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _hashProposition(IWallet.Proposition memory proposition)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _PROPOSITION_TYPEHASH,
                    proposition.endsAt,
                    LibEIP712Transaction._hashTransaction(proposition.tx),
                    proposition.relevantHash
                )
            );
    }

    function _toTypedDataHash(IWallet.Proposition memory proposition)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashProposition(proposition));
    }
}