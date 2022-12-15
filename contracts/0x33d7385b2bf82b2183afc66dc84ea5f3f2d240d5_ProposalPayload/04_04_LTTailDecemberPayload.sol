// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice Tail assets LT changes
 * Governance Forum Post: https://governance.aave.com/t/arc-risk-parameter-updates-for-aave-v2-ethereum-lts-and-ltvs-for-long-tail-assets-2022-12-04/10926
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xd706dfcb631076d5e835e0640d120b8de333d31ef30f66e3dbb529a380608ea1
 */
contract ProposalPayload {
    address public constant ENS = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
    uint256 public constant ENS_LTV = 4700; /// 50 -> 47
    uint256 public constant ENS_LIQUIDATION_THRESHOLD = 5700; // 60 -> 57
    uint256 public constant ENS_LIQUIDATION_BONUS = 10800; //unchanged

    address public constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    uint256 public constant MKR_LTV = 6200; /// 65 -> 62
    uint256 public constant MKR_LIQUIDATION_THRESHOLD = 6700; // 70 -> 67
    uint256 public constant MKR_LIQUIDATION_BONUS = 10750; //unchanged

    address public constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    uint256 public constant SNX_LTV = 4600; /// 49 -> 46
    uint256 public constant SNX_LIQUIDATION_THRESHOLD = 6200; // 65 -> 62
    uint256 public constant SNX_LIQUIDATION_BONUS = 10750; //unchanged

    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    uint256 public constant CRV_LTV = 5200; /// 55 -> 52
    uint256 public constant CRV_LIQUIDATION_THRESHOLD = 5800; // 61 -> 58
    uint256 public constant CRV_LIQUIDATION_BONUS = 10800; //unchanged

    function execute() external {
        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            ENS,
            ENS_LTV,
            ENS_LIQUIDATION_THRESHOLD,
            ENS_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            MKR,
            MKR_LTV,
            MKR_LIQUIDATION_THRESHOLD,
            MKR_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            SNX,
            SNX_LTV,
            SNX_LIQUIDATION_THRESHOLD,
            SNX_LIQUIDATION_BONUS
        );

        AaveV2Ethereum.POOL_CONFIGURATOR.configureReserveAsCollateral(
            CRV,
            CRV_LTV,
            CRV_LIQUIDATION_THRESHOLD,
            CRV_LIQUIDATION_BONUS
        );
    }
}