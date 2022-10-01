// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {IAaveEcosystemReserveController} from "./external/aave/IAaveEcosystemReserveController.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Llama <> AAVE Proposal
 * @author Llama
 * @notice Payload to execute the Llama <> AAVE Proposal
 * Governance Forum Post: https://governance.aave.com/t/updated-proposal-llama-aave/9924
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x9f65a598bee69a1dd84127d712ffedbc0795f0647e89056a297cae998dd18bf1
 */
contract ProposalPayload {
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    // Reserve that holds AAVE tokens
    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    // Llama Recipient address
    address public constant LLAMA_RECIPIENT = 0xb428C6812E53F843185986472bb7c1E25632e0f7;

    address public constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    // 350,000 aUSDC = $0.35 Million
    uint256 public constant AUSDC_UPFRONT_AMOUNT = 350000e6;
    // 1,813.68 AAVE = $0.15 Million using 30 day TWAP on day of proposal
    uint256 public constant AAVE_UPFRONT_AMOUNT = 181368e16;

    // ~700,000 aUSDC = $0.7 million
    // Small additional amount to handle remainder condition during streaming
    // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
    uint256 public constant AUSDC_STREAM_AMOUNT = 700000e6 + 26624000;
    // ~3,627.35 AAVE = $0.3 Million using 30 day TWAP on day of proposal
    // Small additional amount to handle remainder condition during streaming
    // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
    uint256 public constant AAVE_STREAM_AMOUNT = 362735e16 + 7552000;
    // 12 months of 30 days
    uint256 public constant STREAMS_DURATION = 360 days;

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Upfront Payment
        // Transfer of the upfront aUSDC payment: $0.35 million in aUSDC
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).transfer(
            AaveV2Ethereum.COLLECTOR,
            AUSDC_TOKEN,
            LLAMA_RECIPIENT,
            AUSDC_UPFRONT_AMOUNT
        );
        // Transfer of the upfront AAVE payment: $0.15 million in AAVE (using 30 day TWAP on day of proposal)
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).transfer(
            AAVE_ECOSYSTEM_RESERVE,
            AAVE_TOKEN,
            LLAMA_RECIPIENT,
            AAVE_UPFRONT_AMOUNT
        );

        // Creation of the streams
        // Stream of $0.7 million in aUSDC over 12 months
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            LLAMA_RECIPIENT,
            AUSDC_STREAM_AMOUNT,
            AUSDC_TOKEN,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );
        // Stream of $0.3 million in AAVE over 12 months (using 30 day TWAP on day of proposal)
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AAVE_ECOSYSTEM_RESERVE,
            LLAMA_RECIPIENT,
            AAVE_STREAM_AMOUNT,
            AAVE_TOKEN,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );
    }
}