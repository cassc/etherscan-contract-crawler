// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

import {Constants} from "../libraries/Constants.sol";

interface IVaultStorage {
    function orderEthUsdcLower() external view returns (int24);

    function orderEthUsdcUpper() external view returns (int24);

    function orderOsqthEthLower() external view returns (int24);

    function orderOsqthEthUpper() external view returns (int24);

    function accruedFeesEth() external view returns (uint256);

    function accruedFeesUsdc() external view returns (uint256);

    function accruedFeesOsqth() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function timeAtLastRebalance() external view returns (uint256);

    function ivAtLastRebalance() external view returns (uint256);

    function totalValue() external view returns (uint256);

    function setParamsBeforeDeposit(
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _ethPriceAtLastRebalance
    ) external;

    function rebalanceTimeThreshold() external view returns (uint256);

    function ethPriceAtLastRebalance() external view returns (uint256);

    function rebalanceThreshold() external view returns (uint256);

    function rebalancePriceThreshold() external view returns (uint256);

    function maxPriceMultiplier() external view returns (uint256);

    function minPriceMultiplier() external view returns (uint256);

    function depositCount() external view returns (uint256);

    function setDepositCount(uint256 _depositCount) external;

    function auctionTime() external view returns (uint256);

    function adjParam() external view returns (uint256);

    function twapPeriod() external view returns (uint32);

    function baseThreshold() external view returns (int24);

    function tickSpacing() external view returns (int24);

    function updateAccruedFees(
        uint256,
        uint256,
        uint256
    ) external;

    function setAccruedFeesEth(uint256) external;

    function setAccruedFeesUsdc(uint256) external;

    function setAccruedFeesOsqth(uint256) external;

    function cap() external view returns (uint256);

    function setSnapshot(
        int24 _orderEthUsdcLower,
        int24 _orderEthUsdcUpper,
        int24 _orderOsqthEthLower,
        int24 _orderOsqthEthUpper,
        uint256 _timeAtLastRebalance,
        uint256 _ivAtLastRebalance,
        uint256 _totalValue,
        uint256 _ethPriceAtLastRebalance
    ) external;

    function isSystemPaused() external view returns (bool);

    function governance() external view returns (address);

    function keeper() external view returns (address);

    function setGovernance(address _governance) external;

    function setKeeper(address _keeper) external;
}