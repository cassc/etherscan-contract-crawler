// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


interface IAntisnipe {
    struct Sniper {
        uint112 status;
        bool isSniper;
        bool isInRevokeList;
        bool isRevokeWhitelist;
    }

    function setConfidant(address confidant) external;

    function removeConfidant(address confidant) external;

    function setAntisnipeBlocksNum(uint256 value) external;

    function setToken(address tokenAdress) external;

    function setStartBlock(uint256 value) external;

    function setMaxSwapQuantity(uint256 value) external;

    function setPancakePair(address value) external;

    function setSnipersLim(uint256 value) external;

    function setRandomModulus(uint256 value) external;

    function setSniperStatus(address sniperAddress, uint112 status) external;

    function setRevokeWhitelist(address whitelistAddress, bool isRevokeWhitelist) external;
    function revoke() external;

    function checkSniper(address from, address to, uint256 value) external returns (bool);
}