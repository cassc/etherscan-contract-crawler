// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @notice Base for moonbirds-related contracts that delegate token-gated
 * actions via EIP712 signatures.
 */
contract MoonbirdAuthBase is EIP712 {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if a delegated function is called with invalid signature.
     */
    error NotAuthorised();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The moonbirds contract
     */
    IERC721 private immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Keeps track of addresses that are block from delegation.
     * @dev Delegator => Target => BlockFlag
     */
    mapping(address => mapping(address => bool)) private _blocked;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        IERC721 moonbirds,
        string memory name,
        string memory version
    ) EIP712(name, version) {
        _moonbirds = moonbirds;
    }

    // =========================================================================
    //                           External
    // =========================================================================

    /**
     * @notice The EIP712 domain separator of this contract.
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Block future and past authorisations for a given target address.
     */
    function blockAuthorisation(address target, bool toggle) external {
        _blocked[msg.sender][target] = toggle;
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    /**
     * @notice Checks if a given Authorisation was correctly signed by the
     * moonbird owner.
     * @dev Returns false, if an address is blocked by the Moonbird owner.
     */
    function _isSignedByMoonbirdOwner(
        uint256 tokenId,
        MoonbirdAuthLib.MoonbirdAuthorisation memory auth,
        bytes memory signature
    ) internal view returns (bool) {
        address owner = _moonbirds.ownerOf(tokenId);

        if (_blocked[owner][msg.sender]) {
            return false;
        }

        return
            MoonbirdAuthLib.validate(
                _domainSeparatorV4(),
                auth,
                owner,
                signature
            );
    }

    /**
     * @notice Allows only callers that have been authorised by the moonbird
     * owner.
     * @dev Reverts otherwise.
     */
    modifier onlyMoonbirdOwnerAuthorisedSender(
        uint256 tokenId,
        bytes memory signature
    ) {
        if (
            !_isSignedByMoonbirdOwner(
                tokenId,
                MoonbirdAuthLib.MoonbirdAuthorisation({target: msg.sender}),
                signature
            )
        ) {
            revert NotAuthorised();
        }
        _;
    }
}

/**
 * @notice Helper library to deal with the delegation of token-gated actions.
 */
library MoonbirdAuthLib {
    /**
     * @notice The authorisation struct to be signed by the moonbird owner.
     */
    struct MoonbirdAuthorisation {
        address target;
    }

    /**
     * @notice The authorisation hash
     */
    bytes32 public constant MOONBIRD_AUTHORISATION_HASH =
        keccak256(bytes("MoonbirdAuthorisation(address target)"));

    /**
     * @notice Computes the EIP712 digest that will be signed.
     */
    function digest(bytes32 domainSeparator, MoonbirdAuthorisation memory auth)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSA.toTypedDataHash(
                domainSeparator,
                keccak256(abi.encode(MOONBIRD_AUTHORISATION_HASH, auth.target))
            );
    }

    /**
     * @notice Checks if a given authorisation struct was correctly signed by a
     * given signer.
     */
    function validate(
        bytes32 domainSeparator,
        MoonbirdAuthorisation memory auth,
        address signer,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = digest(domainSeparator, auth);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }
}