// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerProxy {
    function setSporkProxy(address payable _sporkProxy) external;
}