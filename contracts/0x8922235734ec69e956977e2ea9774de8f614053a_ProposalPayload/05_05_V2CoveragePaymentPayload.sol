// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveMisc, IAaveEcosystemReserveController} from "@aave-address-book/AaveMisc.sol";

/**
 * @title Chaos Labs - Aave v2 Coverage Proposal
 * @author Chaos
 * @notice Payload to execute the Chaos Labs - Aave v2 Coverage Proposal
 * Governance Forum Post: https://governance.aave.com/t/arc-chaos-labs-aave-v2-coverage/11012
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xd4df8cd3ef68f787d08cd0f8c529471ed48d70ebc15a562a39dbc0196a9f8e47
 */
contract ProposalPayload {
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    // Chaos Recipient address
    address public constant CHAOS_RECIPIENT = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;

    address public constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    // ~175,000 aUSDC = $175,000
    // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
    uint256 public constant AUSDC_STREAM_AMOUNT = 175000e6;

    // Aave token 30 days TWAP price 22/11-21/12 is $60.378
    // ~1242 aAAVE = $75,000
    uint256 public constant AAVE_STREAM_AMOUNT = 1242e18;

    // 5 months of 30 days
    uint256 public constant STREAMS_DURATION = 150 days; // 5 months duration

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // rounding due to:
        // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
        uint256 actualAmountUSDC = (AUSDC_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION; // rounding
        uint256 actualAmountAave = (AAVE_STREAM_AMOUNT / STREAMS_DURATION) * STREAMS_DURATION; // rounding
        // Creation of the streams
        // Stream of $175,000 in aUSDC over 5 months
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            CHAOS_RECIPIENT,
            actualAmountUSDC,
            AUSDC_TOKEN,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );

        // Stream of $75,000 in AAVE over 5 months (using 30 day TWAP on day of proposal)
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveMisc.ECOSYSTEM_RESERVE,
            CHAOS_RECIPIENT,
            actualAmountAave,
            AAVE_TOKEN,
            block.timestamp,
            block.timestamp + STREAMS_DURATION
        );
    }
}