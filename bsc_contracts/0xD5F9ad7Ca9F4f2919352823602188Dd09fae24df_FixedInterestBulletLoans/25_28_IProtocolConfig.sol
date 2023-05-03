// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IProtocolConfig {
    error NotProtocolAdmin();

    event ProtocolAdminChanged(address protocolAdmin);
    event PauserChanged(address pauser);

    function protocolAdmin() external view returns (address);

    function pauser() external view returns (address);
}