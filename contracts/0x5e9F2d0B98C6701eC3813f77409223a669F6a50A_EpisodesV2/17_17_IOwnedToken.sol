// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOwnedToken {
    function ownerOf(uint256) external view returns (address);
}