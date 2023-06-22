// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct ShipInfo {
    uint96 spins;
    uint96 spinsBurned;
    uint40 lastServiceTime;
    string name;
}

interface IMiaocraft is IERC721 {
    event Build(
        address indexed owner,
        uint256 indexed id,
        uint256 spins,
        string name
    );

    event Upgrade(address indexed owner, uint256 indexed id, uint256 spins);

    event Merge(
        address indexed owner,
        uint256 indexed id1,
        uint256 indexed id2,
        uint256 spins
    );

    event Scrap(
        address indexed scavengerOwner,
        uint256 indexed scavengerId,
        uint256 indexed targetId
    );

    event Service(
        address indexed owner,
        uint256 indexed id,
        uint256 spins,
        uint256 cost
    );

    event Rename(address indexed owner, uint256 indexed id, string name);

    function spinsOf(uint256 id) external view returns (uint256);

    function spinsDecayOf(uint256 id) external view returns (uint256);

    function buildCost(uint256 spins_) external view returns (uint256);

    function serviceCostOf(uint256 id) external view returns (uint256);

    function getShipInfo(uint256 id) external view returns (ShipInfo memory);

    function build(uint256 spins_, string calldata name_) external;

    function upgrade(uint256 id, uint256 spins_) external;

    function merge(uint256 id1, uint256 id2) external;

    function scrap(uint256 scavengerId, uint256 targetId) external;

    function service(uint256 id) external;

    function rename(uint256 id, string calldata name_) external;

    function isApprovedOrOwner(address spender, uint256 id)
        external
        view
        returns (bool);
}