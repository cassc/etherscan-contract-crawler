// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICutUpGeneration {
    struct Messages {
        string message1;
        string message2;
        string message3;
        string message4;
        string message5;
        string message6;
        string message7;
        string message8;
        string message9;
        string message10;
        string message11;
        string message12;
    }

    function cutUp(bytes32 seed) external view returns (Messages memory);
}