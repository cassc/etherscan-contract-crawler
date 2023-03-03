// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {AaveV2Ethereum, AaveV2EthereumAssets } from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice MKR LT, LTV changes
 * Governance Forum Post: https://governance.aave.com/t/arc-chaos-labs-risk-parameter-updates-mkr-on-aave-v2-ethereum-2023-02-17/11948
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0x9f2c87a0eb6296ca1ef45bc3ce70cbd7884a0c7b960f17f32a0742abf89c2b8a
 */
contract ProposalPayload {
    address public constant MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    uint256 public constant MKR_LTV = 5900; ///  59
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6400; // 64
    uint256 public constant MKR_LIQUIDATION_BONUS = 10750; //unchanged

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            MKR,
            MKR_LTV,
            MKR_LIQUIDATION_THRESHOLD,
            MKR_LIQUIDATION_BONUS
        );
    }
}