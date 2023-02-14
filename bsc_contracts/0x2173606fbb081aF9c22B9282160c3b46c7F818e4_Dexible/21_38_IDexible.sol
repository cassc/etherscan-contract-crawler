//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./IDexibleView.sol";
import "./ISwapHandler.sol";
import "./IDexibleEvents.sol";
import "./IDexibleConfig.sol";

interface IDexible is IDexibleView, IDexibleConfig, ISwapHandler {

    
}