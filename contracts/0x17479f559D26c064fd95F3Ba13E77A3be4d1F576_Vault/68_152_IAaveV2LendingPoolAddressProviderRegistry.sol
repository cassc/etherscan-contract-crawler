// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IAaveV2LendingPoolAddressProviderRegistry {
    function getAddressesProvidersList() external view returns (address[] memory);

    function getAddressesProviderIdByAddress(address addressesProvider) external view returns (uint256);
}