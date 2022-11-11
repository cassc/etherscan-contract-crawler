// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { IMemberships } from "./IMemberships.sol";

interface IMembershipsFactory {
    function membershipsLatestVersion() external view returns (uint16);

    function membershipsImpls(uint16 version) external view returns (address);

    function feeBPS() external view returns (uint16);

    function feeTreasury() external view returns (address payable);

    function setMembershipsImplAddress(uint16 _version, address _memberships) external;

    function setFeeBPS(uint16 _feeBPS) external;

    function setFeeTreasury(address payable _feeTreasury) external;

    function deployMemberships(bytes memory _data) external returns (address);

    function deployMembershipsAtVersion(uint16 _version, bytes memory _data) external returns (address);

    function upgradeProxy(uint16 _version, address _membershipsProxy) external;
}