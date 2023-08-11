// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MintInternal} from "./MintInternal.sol";
import {MintStorage} from "../../libraries/storage/MintStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  MintFacet
 * @author slvrfn
 * @notice Implementation contract of the abstract MintInternal. The role of this contract is to manage the mint
 *         process and associated control-parameters
 */
contract MintFacet is MintInternal {
    using MintStorage for MintStorage.Layout;

    /**
     * @notice Allows creation of a variable number of NFTs to a chosen holder, using a MintVoucher.
     * @param  holder - recipient of the minted NFTs.
     * @param  mintQty - the chosen quantity of NFTs to mint.
     * @param  voucher - the MintVoucher that acts as a "permission slip" to mint NFTs.
     */
    function createTokens(address holder, uint16 mintQty, MintVoucher calldata voucher) public payable {
        _createTokens(holder, mintQty, voucher);
    }

    /**
     * @notice Update the current Mint phase.
     * @param  newPhase - the new mint phase.
     */
    function setMintingPhase(uint16 newPhase) external onlyRole(keccak256("admin")) {
        _setMintingPhase(newPhase);
    }

    /**
     * @notice Get the current Mint phase.
     */
    function getMintPhase() external view returns (uint16) {
        return _getMintPhase();
    }

    /**
     * @notice Update the max tokens that can be minted by any one address.
     * @param  newMax - the new max.
     */
    function setMaxTokensPerAddress(uint16 newMax) external onlyRole(keccak256("admin")) {
        MintStorage.Layout storage m = MintStorage.layout();
        _setMaxTokensPerAddress(m, newMax);
    }

    /**
     * @notice Get the max tokens that can be minted by any one address.
     */
    function getMaxTokensPerAddress() external view returns (uint16 maxTokensPerAddress) {
        return _getMaxTokensPerAddress();
    }

    /**
     * @notice Update the fee for a specific mint phase.
     * @param  phase - the phase that will have its mint fee updated.
     * @param  newFee - the new mint fee for the provided phase.
     */
    function setMintingFee(uint256 phase, uint256 newFee) external onlyRole(keccak256("admin")) {
        MintStorage.Layout storage m = MintStorage.layout();
        _setMintingFee(m, phase, newFee);
    }

    /**
     * @notice Returns the mint fee for a chosen mint phase.
     * @param  phase - the phase to get the mint fee for.
     */
    function getMintFee(uint256 phase, uint16 qty) external view returns (uint256) {
        return _getMintFee(phase, qty);
    }

    /**
     * @notice Airdrop tokens to an array of recipients.
     * @param  recipients - an array of holders to receive airdropped tokens
     * @param  qtys - array of mint qty(s)
     */
    function airdropTokens(address[] calldata recipients, uint8[] calldata qtys) external onlyRole(keccak256("admin")) {
        _airdropTokens(recipients, qtys);
    }
}