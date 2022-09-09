// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 
import "./IDABotController.sol";
import "./IDABotSettingModule.sol";
import "./IDABotStakingModule.sol";
import "./IDABotGovernModule.sol";
import "./IDABotWhitelist.sol";
import "./IDABotFundManagerModule.sol";

interface IDABot is IDABotController, 
    IDABotSettingModule, 
    IDABotStakingModule, 
    IDABotGovernModule, 
    IDABotWhitelistModule,
    IDABotFundManagerModule 
{
}