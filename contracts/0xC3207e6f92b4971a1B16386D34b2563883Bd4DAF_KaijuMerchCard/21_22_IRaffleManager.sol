// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IRaffleManager {
    struct CreateRaffle {
        uint64 scriptId;
        uint64 winners;
        uint64 endsAt;
    }

    struct Raffle {
        uint256 seed;
        uint64 scriptId;
        uint64 winners;
        uint64 endsAt;
    }

    function get(uint256 id) external view returns (Raffle memory);
    function isDrawn(uint256 id) external view returns (bool);
    function create(uint256 id, CreateRaffle calldata raffle) external;
    function enter(uint256 id, uint32 amount) external;
    function draw(uint256 id, bool vrf) external;
}