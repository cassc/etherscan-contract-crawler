// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ISec {
    // function isOwner(address _owner) external view returns (bool result);

    // function owner() external view returns (address owner);

    function register(address _caOwner) external;

    function addGdAccount(address gdAccount) external;

    function rmGdAccount(address gdAccount) external;
}