// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IAaveV1LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingPoolDataProvider() external view returns (address);
}