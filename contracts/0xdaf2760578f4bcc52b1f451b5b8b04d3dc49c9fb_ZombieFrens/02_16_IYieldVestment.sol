// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @author tempest-sol
interface IYieldVestment {
    function isVested(uint256 tokenId) external view returns (bool vested);
}