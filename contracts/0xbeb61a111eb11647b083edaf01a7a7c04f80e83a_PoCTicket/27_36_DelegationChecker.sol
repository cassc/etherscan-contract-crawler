// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";
import {TokenRedemption} from "poc-ticket/TokenRedemption.sol";
import {PROOFTokens} from "poc-ticket/PROOFTokens.sol";

/**
 * @title Proof of Conference Tickets - PROOF NFT delegation verification module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract DelegationChecker {
    // =========================================================================
    //                           Errors
    // =========================================================================

    error InvalidTokenDelegation(IERC721 token, uint256 tokenId);
    error InvalidContractDelegation(IERC721 token);
    error InvalidDelegation();
    error NoDelegation();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF Collective token.
     */
    IERC721 private immutable _proof;

    /**
     * @notice The Moonbirds token.
     */
    IERC721 private immutable _moonbirds;

    /**
     * @notice The Oddities token.
     */
    IERC721 private immutable _oddities;

    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegationRegistry private immutable _delegationRegistry;

    // =========================================================================
    //                           Construction
    // =========================================================================

    constructor(
        PROOFTokens memory tokens,
        IDelegationRegistry delegationRegistry
    ) {
        _proof = tokens.proof;
        _moonbirds = tokens.moonbirds;
        _oddities = tokens.oddities;
        _delegationRegistry = delegationRegistry;
    }

    // =========================================================================
    //                           Checks
    // =========================================================================

    /**
     * @notice Checks if the delegate has sufficient delegations to redeem PoC
     * tickets using the supplied tokens.
     * @dev Reverts otherwise.
     */
    function _checkDelegation(
        address delegate,
        address delegator,
        IDelegationRegistry.DelegationType delegationType,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions
    ) internal view {
        if (delegationType == IDelegationRegistry.DelegationType.ALL) {
            if (_delegationRegistry.checkDelegateForAll(delegate, delegator)) {
                return;
            }
            revert InvalidDelegation();
        }

        if (delegationType == IDelegationRegistry.DelegationType.CONTRACT) {
            if (pcRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _proof);
            }
            if (mbRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _moonbirds);
            }
            if (oddRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _oddities);
            }
            return;
        }

        if (delegationType == IDelegationRegistry.DelegationType.TOKEN) {
            _checkTokenDelegation(delegate, delegator, _proof, pcRedemptions);
            _checkTokenDelegation(
                delegate, delegator, _moonbirds, mbRedemptions
            );
            _checkTokenDelegation(
                delegate, delegator, _oddities, oddRedemptions
            );
            return;
        }

        revert NoDelegation();
    }

    /**
     * @notice Checks if the delegate has a contract-wide delegation for the
     * specified token if the list of redemptions is not empty.
     * @dev Reverts otherwise.
     */
    function _checkContractDelegation(
        address delegate,
        address delegator,
        IERC721 token
    ) private view {
        if (
            !_delegationRegistry.checkDelegateForContract(
                delegate, delegator, address(token)
            )
        ) {
            revert InvalidContractDelegation(token);
        }
    }

    /**
     * @notice Checks if the delegate has a token-specific delegation for the
     * redeeming tokens
     * @dev Reverts otherwise.
     */
    function _checkTokenDelegation(
        address delegate,
        address delegator,
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) private view {
        for (uint256 i; i < redemptions.length; ++i) {
            if (
                !_delegationRegistry.checkDelegateForToken(
                    delegate, delegator, address(token), redemptions[i].tokenId
                )
            ) {
                revert InvalidTokenDelegation(token, redemptions[i].tokenId);
            }
        }
    }
}