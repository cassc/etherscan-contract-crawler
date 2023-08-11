// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IAaveV2LendingPoolAddressesProvider {
    function getMarketId() external view returns (string memory);

    function getAddress(bytes32 _id) external view returns (address);

    function getLendingPool() external view returns (address);

    function getLendingPoolCollateralManager() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingRateOracle() external view returns (address);
}