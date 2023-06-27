// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

/// Gro Vester interface - used to move vesting tokens into the bonus contract
interface IVester {
    function exit(uint256 amount) external;
}