// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    struct CompanyInfo {
        uint256 jurisdiction;
        uint256 entityType;
        string ein;
        string dateOfIncorporation;
        uint256 fee;
    }

    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external returns (CompanyInfo memory);
}