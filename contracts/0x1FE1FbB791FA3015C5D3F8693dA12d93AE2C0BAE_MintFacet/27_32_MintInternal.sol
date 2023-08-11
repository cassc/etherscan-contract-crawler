// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {ERC721BaseInternal} from "@solidstate/contracts/token/ERC721/base/ERC721Base.sol";
import {ERC721EnumerableInternal} from "@solidstate/contracts/token/ERC721/enumerable/ERC721EnumerableInternal.sol";
import {FeatureFlag} from "../../base/FeatureFlag.sol";
import {TokenStorage} from "../../libraries/storage/TokenStorage.sol";
import {MintStorage} from "../../libraries/storage/MintStorage.sol";
import {BaseStorage} from "../../base/BaseStorage.sol";
import {MintVoucherVerifier} from "../../base/MintVoucherVerifier.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  MintInternal
 * @author slvrfn
 * @notice Abstract contract which contains the necessary logic to manage the mint process and associated
 *         control-parameters
 * @dev    This contract is meant to be inherited by contracts so they can use the internal functions
 *         as desired
 */
abstract contract MintInternal is BaseStorage, AccessControlInternal, FeatureFlag, MintVoucherVerifier, ERC721BaseInternal, ERC721EnumerableInternal {
    using TokenStorage for TokenStorage.Layout;
    using MintStorage for MintStorage.Layout;

    /**
     * @dev Broadcast when the minting fee is updated
     */
    event UpdateMintingFee(uint256 phase, uint256 fee);
    /**
     * @dev Broadcast when the max tokens per address limit is updated
     */
    event UpdateMaxTokensPerAddress(uint16 count);
    /**
     * @dev Broadcast when the current mint phase is updated
     */
    event UpdateMintPhase(uint16 phase);
    /**
     * @dev Raised if a user tries to mint through a smart contract.
     */
    error SmartContract();

    /**
     * @notice See {ERC721BaseInternal-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev   Increments the overall token id counter and mints a NFT to the provided holder.
     * @param holder - the recipient of the token being minted.
     */
    function __mintToken(MintStorage.Layout storage m, address holder) internal virtual {
        uint216 tokenId = m._postincTokenIdCounter();

        super._safeMint(holder, tokenId);
    }

    /**
     * @dev   Allows minting several NFTs at once, Incrementing the overall token id counter and mints the qty of
     *        tokens to the provided holder.
     * @param holder - the recipient of the token being minted.
     * @param qty - the number of NFTs to be minted.
     */
    function __mintTokens(MintStorage.Layout storage m, address holder, uint256 qty) internal virtual {
        for (uint i = 0; i < qty; ) {
            __mintToken(m, holder);

            // save some gas
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev   Checks additional features of the voucher to make sure it is being consumed when/how expected.
     * @param voucherSigner - the signer of the MintVoucher.
     * @param qty - the number of NFTs to be minted.
     */
    function _ensureCanMintQty(MintStorage.Layout storage m, address voucherSigner, uint16 qty) internal virtual {
        uint16 desiredQty = 0;
        uint16 currentPhase = m._mintPhase();

        bytes32 checkRole = bytes32(0);
        // determine the expected role based on phase
        if (currentPhase == 1) {
            // only members of FriendsList
            checkRole = keccak256("friendsSigner");
        } else if (currentPhase == 2) {
            // members of FriendsList & FCFS
            checkRole = keccak256("fcfsSigner");
        } else if (currentPhase == 3) {
            // everyone can mint in public
            checkRole = keccak256("publicSigner");
        }

        uint256 remaining = 0;

        // check if the voucher being used has the correct role based on phase
        if (checkRole != bytes32(0) && _hasRole(checkRole, voucherSigner)) {
            // remaining tokens an address can mint
            // users can mint up to the max per address limit
            uint16 maxPerAddress = m._maxTokensPerAddress();
            uint256 mintedPerAddress = m._tokensMintedPerAddress(msg.sender);
            if (mintedPerAddress > maxPerAddress) {
                revert MintLimit();
            }
            remaining = maxPerAddress - mintedPerAddress;
            desiredQty = qty;
        }
        // otherwise, user is not allowed to mint/or attempted out of assigned phase
        else {
            revert VoucherInvalid();
        }

        // remaining > count >= 1
        if ((desiredQty > remaining) || (desiredQty < 1)) {
            // Cannot mint more than the maximum
            revert MintLimit();
        }
        m._incTokensMintedPerAddress(msg.sender, desiredQty);
    }

    /**
     * @dev   Allows creation of a variable number of NFTs to a chosen holder, using a MintVoucher.
     * @param holder - recipient of the minted NFTs.
     * @param mintQty - the chosen quantity of NFTs to mint.
     * @param voucher - the MintVoucher that acts as a "permission slip" to mint NFTs.
     */
    function _createTokens(address holder, uint16 mintQty, MintVoucher calldata voucher) internal virtual {
        // prevent smart contracts from being able to initiate mint
        // the holder can still be a smart-contract (vault/etc)
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) {
            revert SmartContract();
        }

        _requireFeaturesEnabled(0, PAUSED_FLAG_BIT | MINT_FLAG_BIT);

        MintStorage.Layout storage m = MintStorage.layout();

        uint40 currentPhase = m._mintPhase();

        // mint has ended
        if (currentPhase != 3) {
            revert MintPhase();
        }

        // check voucher is valid, and claim it if not in the public mint
        // voucher should be claimed when mintPhase!=3 OR voucher is free mint
        address voucherSigner = _checkVoucherGetSigner(voucher, currentPhase, mintQty, currentPhase != 3 || voucher.free != 0);

        // check if user allowed to mint based on voucher-role/own-role/phase
        _ensureCanMintQty(m, voucherSigner, mintQty);

        // if only minting 1 token, no need to allocate extra memory
        if (voucher.qty == 1) {
            __mintToken(m, holder);
            return;
        }

        __mintTokens(m, holder, mintQty);
    }

    /**
     * @dev   Returns the mint fee for a chosen mint phase.
     * @param currentPhase - the phase to get the mint fee for.
     */
    function _getMintFee(uint256 currentPhase, uint16 qty) internal virtual view override(MintVoucherVerifier) returns (uint256) {
        return MintStorage.layout()._phaseFee(currentPhase) * qty;
    }

    /**
     * @dev   Update the current Mint phase.
     * @param newPhase - the new mint phase.
     */
    function _setMintingPhase(uint16 newPhase) internal virtual {
        MintStorage.Layout storage m = MintStorage.layout();
        m._setMintPhase(newPhase);
        emit UpdateMintPhase(newPhase);
    }

    /**
     * @dev   Get the current Mint phase.
     */
    function _getMintPhase() internal virtual view returns (uint16) {
        return MintStorage.layout()._mintPhase();
    }

    /**
     * @dev   Update the max tokens that can be minted by any one address.
     * @param newMax - the new max.
     */
    function _setMaxTokensPerAddress(MintStorage.Layout storage m, uint16 newMax) internal virtual {
        m._setMaxTokensPerAddress(newMax);
        emit UpdateMaxTokensPerAddress(newMax);
    }

    /**
     * @dev Get the max tokens that can be minted by any one address.
     */
    function _getMaxTokensPerAddress() internal virtual view returns (uint16 maxTokensPerAddress) {
        return MintStorage.layout()._maxTokensPerAddress();
    }

    /**
     * @dev   Update the fee for a specific mint phase.
     * @param phase - the phase that will have its mint fee updated.
     * @param newFee - the new mint fee for the provided phase.
     */
    function _setMintingFee(MintStorage.Layout storage m, uint256 phase, uint256 newFee) internal virtual {
        m._setPhaseFee(phase, newFee);
        emit UpdateMintingFee(phase, newFee);
    }

    /**
     * @notice Airdrop tokens to an array of recipients.
     * @param  recipients - an array of holders to receive airdropped tokens
     * @param  qtys - array of mint qty(s)
     */
    function _airdropTokens(address[] calldata recipients, uint8[] calldata qtys) internal virtual {
        MintStorage.Layout storage m = MintStorage.layout();
        uint loopQty = qtys.length;
        address holder;
        uint8 holderQty;
        for (uint i = 0; i < loopQty; ) {
            holder = recipients[i];
            holderQty = qtys[i];

            if (holderQty == 1) {
                __mintToken(m, holder);
            } else{
                __mintTokens(m, holder, holderQty);
            }

            // save some gas
            unchecked {
                ++i;
            }
        }
    }
}