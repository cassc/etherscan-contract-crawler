// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.10;

interface IRiskManager {
    struct LiquidityStatus {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 numBorrows;
        bool borrowIsolated;
    }

    function computeLiquidity(address account) external view returns (LiquidityStatus memory status);

    function getPrice(address underlying) external view returns (uint256 twap, uint256 twapPeriod);
}