//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "./IWallet.sol";

/// @author Amit Molek
/// @dev EIP712 Proposition struct signature verification for Antic domain
interface IEIP712Proposition {
    /// @param signer the account you want to check that signed
    /// @param proposition the proposition to verify
    /// @param signature the supposed signature of `signer` on `proposition`
    /// @return true if `signer` signed `proposition` using `signature`
    function verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (bool);

    /// @param proposition the proposition
    /// @param signature the account's signature on `proposition`
    /// @return the address that signed on `proposition`
    function recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (address);

    function hashProposition(IWallet.Proposition memory proposition)
        external
        pure
        returns (bytes32);
}