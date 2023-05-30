// contracts/Incubator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Incubator {
    function incubate(uint256 _vialId, address _to) external;
}