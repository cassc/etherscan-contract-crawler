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
}