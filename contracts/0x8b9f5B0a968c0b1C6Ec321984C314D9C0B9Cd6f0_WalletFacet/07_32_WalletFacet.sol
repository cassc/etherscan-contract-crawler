//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../../interfaces/IWallet.sol";
import {LibWallet} from "../../libraries/LibWallet.sol";
import {LibEIP712Proposition} from "../../libraries/LibEIP712Proposition.sol";

/// @title Multisig wallet facet
/// @author Amit Molek
/// @dev Please see `IWallet` for docs.
contract WalletFacet is IWallet {
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external override returns (bool successful, bytes memory returnData) {
        return LibWallet._untrustedEnactProposition(proposition, signatures);
    }

    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        override
        returns (bool)
    {
        return LibWallet._isPropositionEnacted(propositionHash);
    }

    function maxAllowedTransfer() external view override returns (uint256) {
        return LibWallet._maxAllowedTransfer();
    }

    /// @return The typed data hash of `proposition`
    function propositionToTypedDataHash(IWallet.Proposition memory proposition)
        external
        view
        returns (bytes32)
    {
        return LibEIP712Proposition._toTypedDataHash(proposition);
    }
}