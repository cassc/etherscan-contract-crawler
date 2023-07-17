// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Rockify} from "./Rockify.sol";

/**
 * @title EtherRoXXConstantsEventsAndErrors
 * @author emo.eth, aspyn.eth
 * @notice Constants, events, and errors for use in EtherRoXX contract.
 */
contract EtherRoXXConstantsEventsAndErrors {
    uint256 constant MAX_SUPPLY = 969;
    uint256 constant MAX_MINT_PER_TRANSACTION = 10;
    uint256 constant OWNER_OF_SELECTOR = 0x6352211e;
    uint256 constant CALLER_DOES_NOT_OWN_XXYYZZ_COLOR_ERROR_SELECTOR = 0x82c7950c;
    uint256 constant ETHER_TRANSFER_FAILED_SELECTOR = 0x6747a288;
    uint256 constant TRANSFER_FROM_SELECTOR = 0x23b872dd;

    error MaxSupplyReached();
    error MaxMintPerTransactionExceeded();
    error CallerDoesNotOwnXXYYZZColor();
    error CallerDoesNotOwnEtherRoXX();
    error InvalidPayment();
    error InvalidHex();
    error EtherTransferFailed();
    error ArrayLengthMustBeGreaterThanZero();
}