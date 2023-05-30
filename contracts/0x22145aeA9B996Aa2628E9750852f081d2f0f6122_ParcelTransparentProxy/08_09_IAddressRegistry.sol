// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAddressRegistry {
    function isWhitelisted(
        address _implementation
    ) external view returns (bool);
}