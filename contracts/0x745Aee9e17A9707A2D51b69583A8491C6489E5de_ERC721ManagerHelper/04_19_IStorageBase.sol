// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IStorageBase {
    function setOwner(address _newOwner) external;

    function setOwnerHelper(address _newOwnerHelper) external;
}