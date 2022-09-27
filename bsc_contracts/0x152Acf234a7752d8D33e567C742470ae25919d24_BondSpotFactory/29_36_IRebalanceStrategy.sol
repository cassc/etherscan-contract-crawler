// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../spot-exchange/libraries/liquidity/Grid.sol";

interface IRebalanceStrategy {
    function getSupplyPrices(
        uint128 currentPip,
        uint128 quote,
        uint128 base
    ) external view returns (Grid.GridOrderData[] memory);

    function getNumberOfSupplyOrdersEachSide() external view returns (uint16);
}