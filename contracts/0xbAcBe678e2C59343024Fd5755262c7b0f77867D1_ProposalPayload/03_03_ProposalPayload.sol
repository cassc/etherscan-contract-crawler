// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum, AaveV2EthereumAssets} from "aave-address-book/AaveV2Ethereum.sol";

/**
 * @title CRV Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend CRV interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-crv-interest-rate-curve-upgrade/11337
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x56aaf192f5cad8277b0e7c82abad030c62bb8fcfe4f2640ce5b896ab04397c20
 */
contract ProposalPayload {
    address public constant INTEREST_RATE_STRATEGY = 0xA4C2C730A4c01c64d54ce0165c27120989A3C743;

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(
            AaveV2EthereumAssets.CRV_UNDERLYING,
            INTEREST_RATE_STRATEGY
        );
    }
}