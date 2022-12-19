//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IEIP712Transaction} from "../../interfaces/IEIP712Transaction.sol";
import {LibEIP712Transaction} from "../../libraries/LibEIP712Transaction.sol";
import {IWallet} from "../../interfaces/IWallet.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Transaction` for docs
contract EIP712TransactionFacet is IEIP712Transaction {
    function verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view override returns (bool) {
        return
            LibEIP712Transaction._verifyTransactionSigner(
                signer,
                transaction,
                signature
            );
    }

    function recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view override returns (address) {
        return
            LibEIP712Transaction._recoverTransactionSigner(
                transaction,
                signature
            );
    }

    function hashTransaction(IWallet.Transaction memory transaction)
        external
        pure
        override
        returns (bytes32)
    {
        return LibEIP712Transaction._hashTransaction(transaction);
    }
}