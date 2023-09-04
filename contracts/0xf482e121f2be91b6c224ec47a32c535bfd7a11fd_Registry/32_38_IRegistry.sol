// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICompaniesRegistry.sol";
import "./ITokensRegistry.sol";
import "./IRecordsRegistry.sol";
import "../IService.sol";

interface IRegistry is ITokensRegistry, ICompaniesRegistry, IRecordsRegistry {
    function service() external view returns (IService);

    function COMPANIES_MANAGER_ROLE() external view returns (bytes32);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function log(
        address sender,
        address receiver,
        uint256 value,
        bytes memory data
    ) external;

    function getPoolAddressByIndex(uint256 index) external view returns (address);

    function getAvailableCompanyAddress(
        uint256 jurisdiction,
        uint256 entityType
    ) external view returns (address);
}