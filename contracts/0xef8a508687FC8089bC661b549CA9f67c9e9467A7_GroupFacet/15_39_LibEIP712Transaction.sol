//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Transaction` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Transaction {
    bytes32 internal constant _TRANSACTION_TYPEHASH =
        keccak256("Transaction(address to,uint256 value,bytes data)");

    function _verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _hashTransaction(IWallet.Transaction memory transaction)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _TRANSACTION_TYPEHASH,
                    transaction.to,
                    transaction.value,
                    keccak256(transaction.data)
                )
            );
    }

    function _toTypedDataHash(IWallet.Transaction memory transaction)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashTransaction(transaction));
    }
}