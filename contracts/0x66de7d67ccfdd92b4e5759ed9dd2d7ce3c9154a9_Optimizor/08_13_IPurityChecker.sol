// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPurityChecker {
    /// @return True if the code of the given account satisfies the code purity requirements.
    function check(address account) external view returns (bool);
}