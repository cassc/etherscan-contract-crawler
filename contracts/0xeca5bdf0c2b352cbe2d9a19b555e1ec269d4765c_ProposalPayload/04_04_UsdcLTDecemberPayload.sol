// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice USDC LT changes
 * Governance Forum Post: https://governance.aave.com/t/arc-risk-parameter-updates-for-aave-v2-ethereum-lt-and-ltv-2022-12-01/10897
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x4d69f27a92875170e5db685ecac4c3a41a12d4510b4d98c7faab6150444d5db8
 */
contract ProposalPayload {
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public constant LTV = 8000; /// 87 -> 80
    uint256 public constant LIQUIDATION_THRESHOLD = 8750; // 89 -> 87.5
    uint256 public constant LIQUIDATION_BONUS = 10450; //unchanged - 10450

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            USDC,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );
    }
}