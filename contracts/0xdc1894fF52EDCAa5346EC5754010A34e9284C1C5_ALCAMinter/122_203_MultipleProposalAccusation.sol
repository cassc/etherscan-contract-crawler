// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/libraries/parsers/PClaimsParserLibrary.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/utils/AccusationsLibrary.sol";
import "contracts/libraries/errors/AccusationsErrors.sol";

/// @custom:salt MultipleProposalAccusation
/// @custom:deploy-type deployUpgradeable
/// @custom:salt-type Accusation
contract MultipleProposalAccusation is
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableValidatorPool
{
    mapping(bytes32 => bool) internal _accusations;

    constructor()
        ImmutableFactory(msg.sender)
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableValidatorPool()
    {}

    /// @notice This function validates an accusation of multiple proposals.
    /// @param _signature0 The signature of pclaims0
    /// @param _pClaims0 The PClaims of the accusation
    /// @param _signature1 The signature of pclaims1
    /// @param _pClaims1 The PClaims of the accusation
    /// @return the address of the signer
    function accuseMultipleProposal(
        bytes calldata _signature0,
        bytes calldata _pClaims0,
        bytes calldata _signature1,
        bytes calldata _pClaims1
    ) public view returns (address) {
        // ecrecover sig0/1 and ensure both are valid and accounts are equal
        address signerAccount0 = AccusationsLibrary.recoverMadNetSigner(_signature0, _pClaims0);
        address signerAccount1 = AccusationsLibrary.recoverMadNetSigner(_signature1, _pClaims1);

        if (signerAccount0 != signerAccount1) {
            revert AccusationsErrors.SignersDoNotMatch(signerAccount0, signerAccount1);
        }

        // ensure the hashes of blob0/1 are different
        if (keccak256(_pClaims0) == keccak256(_pClaims1)) {
            revert AccusationsErrors.PClaimsAreEqual();
        }

        PClaimsParserLibrary.PClaims memory pClaims0 = PClaimsParserLibrary.extractPClaims(
            _pClaims0
        );
        PClaimsParserLibrary.PClaims memory pClaims1 = PClaimsParserLibrary.extractPClaims(
            _pClaims1
        );

        // ensure the height of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.height != pClaims1.rCert.rClaims.height) {
            revert AccusationsErrors.PClaimsHeightsDoNotMatch(
                pClaims0.rCert.rClaims.height,
                pClaims1.rCert.rClaims.height
            );
        }

        // ensure the round of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.round != pClaims1.rCert.rClaims.round) {
            revert AccusationsErrors.PClaimsRoundsDoNotMatch(
                pClaims0.rCert.rClaims.round,
                pClaims1.rCert.rClaims.round
            );
        }

        // ensure the chainid of blob0/1 are equal using RCert sub object of PClaims
        if (pClaims0.rCert.rClaims.chainId != pClaims1.rCert.rClaims.chainId) {
            revert AccusationsErrors.PClaimsChainIdsDoNotMatch(
                pClaims0.rCert.rClaims.chainId,
                pClaims1.rCert.rClaims.chainId
            );
        }

        // ensure the chainid of blob0 is correct for this chain using RCert sub object of PClaims
        uint256 chainId = ISnapshots(_snapshotsAddress()).getChainId();
        if (pClaims0.rCert.rClaims.chainId != chainId) {
            revert AccusationsErrors.InvalidChainId(pClaims0.rCert.rClaims.chainId, chainId);
        }

        // ensure both accounts are applicable to a currently locked validator - Note<may be done in different layer?>
        if (!IValidatorPool(_validatorPoolAddress()).isAccusable(signerAccount0)) {
            revert AccusationsErrors.SignerNotValidValidator(signerAccount0);
        }

        return signerAccount0;
    }
}