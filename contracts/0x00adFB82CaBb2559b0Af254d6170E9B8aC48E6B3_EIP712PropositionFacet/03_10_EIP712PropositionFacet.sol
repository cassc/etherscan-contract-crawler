//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IEIP712Proposition} from "../../interfaces/IEIP712Proposition.sol";
import {LibEIP712Proposition} from "../../libraries/LibEIP712Proposition.sol";
import {IWallet} from "../../interfaces/IWallet.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Proposition` for docs
contract EIP712PropositionFacet is IEIP712Proposition {
    function verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view override returns (bool) {
        return
            LibEIP712Proposition._verifyPropositionSigner(
                signer,
                proposition,
                signature
            );
    }

    function recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view override returns (address) {
        return
            LibEIP712Proposition._recoverPropositionSigner(
                proposition,
                signature
            );
    }

    function hashProposition(IWallet.Proposition memory proposition)
        external
        pure
        override
        returns (bytes32)
    {
        return LibEIP712Proposition._hashProposition(proposition);
    }
}