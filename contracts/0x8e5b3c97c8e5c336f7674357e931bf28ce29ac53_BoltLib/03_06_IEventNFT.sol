// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEventNFT {
    struct Event {
        string name;
        string bottomSvg;
        string topSvg;
        string planet1;
        string planet1Svg;
        string planet2;
        string planet2Svg;
        string planet3;
        string planet3Svg;
        string sun;
        string sunSvg;
        uint256 numPlanets;
    }

    struct EventParams {
        string name;
        string bottomSvg;
        string topSvg;
        string planet1;
        string planet1Svg;
        string planet2;
        string planet2Svg;
        string planet3;
        string planet3Svg;
        string sun;
        string sunSvg;
        uint256 numPlanets;
    }

    function getEvent(uint256 eventId) external view returns (Event memory);
}