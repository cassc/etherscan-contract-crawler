// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AllowListData, CreatorPayout } from "./SeaDropStructs.sol";

/**
 * @notice A struct defining public drop data.
 *         Designed to fit efficiently in two storage slots.
 *
 * @param startPrice               The start price per token. (Up to 1.2m
 *                                 of native token, e.g. ETH, MATIC)
 * @param endPrice                 The end price per token. If this differs
 *                                 from startPrice, the current price will
 *                                 be calculated based on the current time.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param paymentToken             The payment token address. Null for
 *                                 native token.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed. (The limit for this field is
 *                                 2^16 - 1)
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct PublicDrop {
    uint80 startPrice; // 80/512 bits
    uint80 endPrice; // 160/512 bits
    uint40 startTime; // 200/512 bits
    uint40 endTime; // 240/512 bits
    address paymentToken; // 400/512 bits
    uint16 maxTotalMintableByWallet; // 416/512 bits
    uint16 feeBps; // 432/512 bits
    bool restrictFeeRecipients; // 440/512 bits
}

/**
 * @notice A struct defining mint params for an allow list.
 *         An allow list leaf will be composed of `msg.sender` and
 *         the following params.
 *
 *         Note: Since feeBps is encoded in the leaf, backend should ensure
 *         that feeBps is acceptable before generating a proof.
 *
 * @param startPrice               The start price per token. (Up to 1.2m
 *                                 of native token, e.g. ETH, MATIC)
 * @param endPrice                 The end price per token. If this differs
 *                                 from startPrice, the current price will
 *                                 be calculated based on the current time.
 * @param startTime                The start time, ensure this is not zero.
 * @param endTime                  The end time, ensure this is not zero.
 * @param paymentToken             The payment token for the mint. Null for
 *                                 native token.
 * @param maxTotalMintableByWallet Maximum total number of mints a user is
 *                                 allowed.
 * @param maxTokenSupplyForStage   The limit of token supply this stage can
 *                                 mint within.
 * @param dropStageIndex           The drop stage index to emit with the event
 *                                 for analytical purposes. This should be
 *                                 non-zero since the public mint emits with
 *                                 index zero.
 * @param feeBps                   Fee out of 10_000 basis points to be
 *                                 collected.
 * @param restrictFeeRecipients    If false, allow any fee recipient;
 *                                 if true, check fee recipient is allowed.
 */
struct MintParams {
    uint256 startPrice;
    uint256 endPrice;
    uint256 startTime;
    uint256 endTime;
    address paymentToken;
    uint256 maxTotalMintableByWallet;
    uint256 maxTokenSupplyForStage;
    uint256 dropStageIndex; // non-zero
    uint256 feeBps;
    bool restrictFeeRecipients;
}

/**
 * @dev Struct containing internal SeaDrop implementation logic
 *      mint details to avoid stack too deep.
 *
 * @param feeRecipient The fee recipient.
 * @param payer        The payer of the mint.
 * @param minter       The mint recipient.
 * @param quantity     The number of tokens to mint.
 * @param withEffects  Whether to apply state changes of the mint.
 */
struct MintDetails {
    address feeRecipient;
    address payer;
    address minter;
    uint256 quantity;
    bool withEffects;
}

/**
 * @notice A struct to configure multiple contract options in one transaction.
 */
struct MultiConfigureStruct {
    uint256 maxSupply;
    string baseURI;
    string contractURI;
    PublicDrop publicDrop;
    string dropURI;
    AllowListData allowListData;
    CreatorPayout[] creatorPayouts;
    bytes32 provenanceHash;
    address[] allowedFeeRecipients;
    address[] disallowedFeeRecipients;
    address[] allowedPayers;
    address[] disallowedPayers;
    // Server-signed
    address[] allowedSigners;
    address[] disallowedSigners;
    // ERC-2981
    address royaltyReceiver;
    uint96 royaltyBps;
    // Mint
    address mintRecipient;
    uint256 mintQuantity;
}