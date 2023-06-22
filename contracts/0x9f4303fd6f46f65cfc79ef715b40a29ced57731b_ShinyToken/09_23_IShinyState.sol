// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShinyState

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

interface IShinyState {
    struct State {
        bool isShiny;
        uint16 shinyChanceBasisPoints;
        uint256 mintedBlock;
        uint256 reconfigurationCount;
    }
}