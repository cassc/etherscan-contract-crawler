// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IStaking.sol";

interface IOldStaking is IStaking {
    function lastClaimed(address) external view returns (uint256);
}