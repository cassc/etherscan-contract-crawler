//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {ConfigTypes} from "../libraries/types/ConfigTypes.sol";

interface ILendingPool {
    event UpdatedBorrowRate(uint256 borrowRate);

    function getUnderlyingBalance() external view returns (uint256);

    function transferUnderlying(
        address to,
        uint256 amount,
        uint256 borrowRate
    ) external;

    function receiveUnderlying(
        address from,
        uint256 amount,
        uint256 borrowRate,
        uint256 interest
    ) external;

    function receiveUnderlyingDefaulted(
        address from,
        uint256 amount,
        uint256 borrowRate,
        uint256 defaultedDebt
    ) external;

    function getSupplyRate() external view returns (uint256);

    function getDebt() external view returns (uint256);

    function getBorrowRate() external view returns (uint256);

    function getUtilizationRate() external view returns (uint256);

    function getPoolConfig()
        external
        view
        returns (ConfigTypes.LendingPoolConfig memory);
}