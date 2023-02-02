// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title BAL Interest Rate Curve Upgrade
 * @author Llama
 * @notice Amend BAL interest rate parameters on the Aave Ethereum v2liquidity pool.
 * Governance Forum Post: https://governance.aave.com/t/arfc-bal-interest-rate-curve-upgrade/10484/10
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xceb72907ec281318c0271039c6cbde07d057e368aff8d8b75ad90389f64bf83c
 */
contract ProposalPayload {
    address public constant INTEREST_RATE_STRATEGY = 0x04c28D6fE897859153eA753f986cc249Bf064f71;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.setReserveInterestRateStrategyAddress(BAL, INTEREST_RATE_STRATEGY);
    }
}