// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IOwnedERC20 {
    function owner() external view returns (address _owner);

    function setOwner(address _owner) external;

    function mint(address recipient, uint256 amount) external;

    function burn(address recipient, uint256 amount) external;
}