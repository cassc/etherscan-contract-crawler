// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {IAaveEcosystemReserveController} from "./external/aave/IAaveEcosystemReserveController.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Gauntlet <> Aave Renewal
 * @author Paul Lei, Deepa Talwar, Jesse Kao, Jonathan Reem, Nick Cannon, Nathan Lord, Watson Fu, Sarah Chen
 * @notice Gauntlet <> Aave Renewal
 * Governance Forum Post: https://governance.aave.com/t/arc-updated-gauntlet-aave-renewal/11013
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xd096f98237c642614fe154844c5037a85c1f287f3323c4b003a83bd3f4ea658a
 */
contract ProposalPayload {
    address public constant BENEFICIARY = 0xD20c9667bf0047F313228F9fE11F8b9F8Dc29bBa;
    // 600,000 aUSDC vaulted upfront amount
    uint256 public constant AUSDC_VAULT_AMOUNT = 600000e6;
    // 9,919 AAVE
    uint256 public constant AAVE_VESTING_AMOUNT = 9919e18; // 18 decimals
    // 800,000 aUSDC
    uint256 public constant AUSDC_VESTING_AMOUNT = 800000e6; // 6 decimals
    uint256 public constant VESTING_DURATION = 360 days;

    // December 31st 2022, 00:00:00 UTC
    uint256 public constant AAVE_VESTING_START = 1672473600;

    address public constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    function execute() external {
        uint256 actualVestingAmountUSDC = (AUSDC_VESTING_AMOUNT / VESTING_DURATION) * VESTING_DURATION; // rounding
        uint256 actualVestingAmountAave = (AAVE_VESTING_AMOUNT / VESTING_DURATION) * VESTING_DURATION; // rounding

        // aUSDC vault transfer
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).transfer(
            AaveV2Ethereum.COLLECTOR,
            AUSDC_TOKEN,
            BENEFICIARY,
            AUSDC_VAULT_AMOUNT
        );

        // aave and ausdc streams

        // aave stream
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AAVE_ECOSYSTEM_RESERVE,
            BENEFICIARY,
            actualVestingAmountAave,
            AAVE_TOKEN,
            AAVE_VESTING_START,
            AAVE_VESTING_START + VESTING_DURATION
        );

        // ausdc stream
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            BENEFICIARY,
            actualVestingAmountUSDC,
            AUSDC_TOKEN,
            AAVE_VESTING_START,
            AAVE_VESTING_START + VESTING_DURATION
        );
    }
}