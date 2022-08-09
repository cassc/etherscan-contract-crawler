// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMembershipsProxy {
    function memberships() external view returns (address);

    function membershipsFactory() external view returns (address);

    function upgradeMemberships(address _memberships) external;
}