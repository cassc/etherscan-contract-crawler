// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IConsent {

    event GrantDegradedServiceConsent(address indexed user, uint256 revocationDeadline);

    event RevokeDegradedServiceConsent(address indexed user);

    function maximumConsentPeriod() external view returns (uint256);

    function userConsentDeadlines(address user) external view returns (uint256);

    function grantDegradedServiceConsent(uint256 revocationDeadline) external;

    function revokeMitigationConsent() external;

    function userConsentsToMitigation(address user) external view returns (bool doesIndeed);

}