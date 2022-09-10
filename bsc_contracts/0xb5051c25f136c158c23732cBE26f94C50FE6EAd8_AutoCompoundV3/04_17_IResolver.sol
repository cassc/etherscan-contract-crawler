// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IResolver {
    function checker(uint256 checker_)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}