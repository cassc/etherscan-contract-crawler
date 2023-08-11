// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

interface IUserPolicies {

    event Deployed(address trustedForwarder, address policyManager);

    event SetUserPolicy(address indexed trader, uint32 indexed policyId);

    event AddApprovedCounterparty(address indexed, address indexed approved);

    event RemoveApprovedCounterparty(address indexed, address indexed approved);

    function userPolicies(address trader) external view returns (uint32);

    function setUserPolicy(uint32 policyId) external;

    function addApprovedCounterparty(address approved) external;

    function addApprovedCounterparties(address[] calldata approved) external;

    function removeApprovedCounterparty(address approved) external;

    function removeApprovedCounterparties(address[] calldata approved) external;

    function approvedCounterpartyCount(address trader) external view returns (uint256 count);

    function approvedCounterpartyAtIndex(address trader, uint256 index) external view returns (address approved);

    function isApproved(address trader, address counterparty) external view returns (bool isIndeed);
}