// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

interface IAaveV1LendingPoolCore {
    function getReserveCurrentLiquidityRate(address _reserve) external view returns (uint256 liquidityRate);

    function getReserveATokenAddress(address _reserve) external view returns (address);

    function getReserveConfiguration(address _reserve)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );
}