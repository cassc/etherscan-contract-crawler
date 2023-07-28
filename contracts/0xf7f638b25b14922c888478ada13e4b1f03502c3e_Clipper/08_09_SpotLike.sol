// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./PipLike.sol";

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint256);

    function poke(bytes32) external;

    function file(bytes32 ilk, bytes32 what, uint data) external;

    function par() external returns (uint256);
}