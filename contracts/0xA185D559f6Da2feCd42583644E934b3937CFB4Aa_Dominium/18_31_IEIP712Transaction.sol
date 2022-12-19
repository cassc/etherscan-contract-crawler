//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "./IWallet.sol";

/// @author Amit Molek
/// @dev EIP712 transaction struct signature verification for Antic domain
interface IEIP712Transaction {
    /// @param signer the account you want to check that signed
    /// @param transaction the transaction to verify
    /// @param signature the supposed signature of `signer` on `transaction`
    /// @return true if `signer` signed `transaction` using `signature`
    function verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view returns (bool);

    /// @param transaction the transaction
    /// @param signature the account's signature on `transaction`
    /// @return the address that signed on `transaction`
    function recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view returns (address);

    function hashTransaction(IWallet.Transaction memory transaction)
        external
        pure
        returns (bytes32);
}