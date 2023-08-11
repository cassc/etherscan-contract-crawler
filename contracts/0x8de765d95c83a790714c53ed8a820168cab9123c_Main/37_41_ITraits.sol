// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

interface ITraits {
    function getTraits(
        uint72 encoded
    ) external view returns (bytes memory attributes);
}