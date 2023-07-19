// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    /**
    * @notice This is how immutable data about companies is stored
    * @dev For companies listed for sale, this data is stored in the Registry in mapping(uint256 => CompanyInfo) public companies. Additionally, this data is duplicated in the Pool contract in IRegistry.CompanyInfo public companyInfo.
    * @param jurisdiction Numeric code for the jurisdiction (region where the company is registered)
    * @param entityType Numeric code for the type of organization
    * @param ein Unique registration number (uniqueness is checked within a single jurisdiction)
    * @param dateOfIncorporation Date of company registration (in the format provided by the jurisdiction)
    * @param fee Fost of the company in wei ETH
    */ 
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

    function createCompany(
        CompanyInfo calldata info
    ) external;
}