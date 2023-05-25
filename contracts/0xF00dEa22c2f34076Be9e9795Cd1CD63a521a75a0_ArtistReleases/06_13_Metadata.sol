/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Metadata {
    struct Meta {
        uint256 created;
        address creator;
        string creatorName;
        address artist;
        string artistName;
        string title;
        uint16 x_shape;
        uint16 y_shape;
        uint256 pointCount;
        string uri;
    }
}