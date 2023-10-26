// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../strategyBase/basic.sol";

contract Events is Basic {
    event EnterProtocol(uint8 protocolId);
    event ExitProtocol(uint8 protocolId);
    event SetVault(address vault);
    event AddRebalancer(address rebalancer);
    event RemoveRebalancer(address rebalancer);
    event UpdateFeeReceiver(address oldFeeReceiver, address newFeeReceiver);
    event UpdateLendingLogic(address oldLendingLogic, address newLendingLogic);
    event UpdateFlashloanHelper(address oldFlashloanHelper, address newFlashloanHelper);
    event UpdateRebalancer(address[] rebalancers, bool[] isAllowed);
    event UpdateRevenueRate(uint256 oldRevenueRate, uint256 newRevenueRate);
    event UpdateSafeAggregatedRatio(uint256 oldSafeAggregatedRatio, uint256 newSafeAggregatedRatio);
    event UpdateSafeProtocolRatio(uint8[] protocolId, uint256[] safeProtocolRatio);
    event CollectRevenue(uint256 revenue);
}