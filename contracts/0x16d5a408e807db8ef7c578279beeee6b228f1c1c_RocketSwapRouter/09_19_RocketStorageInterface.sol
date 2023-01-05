// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

interface RocketStorageInterface {
    function getAddress(bytes32 _key) external view returns (address);
}