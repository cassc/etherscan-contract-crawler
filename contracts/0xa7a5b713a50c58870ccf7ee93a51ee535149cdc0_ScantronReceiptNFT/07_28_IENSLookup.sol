// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9;

interface IENSLookup {
    function getNames(address[] memory addresses)
        external
        view
        returns (string[] memory);
}