// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct LocationInfo {
    int40 xOrigin;
    int40 yOrigin;
    int40 xDest;
    int40 yDest;
    uint40 speed;
    uint40 departureTime;
    bool locked;
}

interface ISpatialSystem {
    event UpdateLocation(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event Move(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event SetLocation(
        uint256 indexed entityId,
        int256 xOrigin,
        int256 yOrigin,
        int256 xDest,
        int256 yDest,
        uint256 speed,
        uint256 departureTime
    );

    event SetCoordinate(uint256 indexed entityId, int256 x, int256 y);

    event Locked(uint256 indexed entityId);

    event Unlocked(uint256 indexed entityId);

    function coordinate(uint256 entityId)
        external
        view
        returns (int256 x, int256 y);

    function collocated(uint256 entityId1, uint256 entityId2)
        external
        view
        returns (bool);

    function collocated(
        uint256 entityId1,
        uint256 entityId2,
        uint256 radius
    ) external view returns (bool);

    function getLocationInfo(uint256 entityId)
        external
        view
        returns (LocationInfo memory);

    function locked(uint256 entityId) external view returns (bool);

    function updateLocation(uint256 entityId) external;
}