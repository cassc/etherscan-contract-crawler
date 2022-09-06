// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IDoorbusterManager {
    struct Doorbuster {
        uint32 supply;
    }

    function get(uint256 id) external view returns (Doorbuster memory);
    function create(uint256 id, uint32 supply) external;
    function purchase(
        uint256 id,
        uint32 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
}