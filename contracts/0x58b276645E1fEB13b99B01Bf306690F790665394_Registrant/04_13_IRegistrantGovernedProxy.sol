// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IRegistrantGovernedProxy {
    function setSporkProxy(address payable _sporkProxy) external;

    function owner() external returns (address);
}