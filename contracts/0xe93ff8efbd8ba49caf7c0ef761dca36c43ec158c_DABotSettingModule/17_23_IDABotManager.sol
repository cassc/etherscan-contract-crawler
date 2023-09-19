// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBotVault.sol";
import "../DABotCommon.sol";
import "../../common/IRoboFiFactory.sol";
import "../../common/IConfigurator.sol";

interface IDABotManagerEvent {
    event BotRemoved(address indexed bot);
    event BotDeployed(uint botId, address indexed bot, BotDetail detail); 
    event TemplateRegistered(address indexed template, string name, string version, uint8 templateType);
}

interface IDABotManager is IDABotManagerEvent {
    
    function configurator() external view returns(IConfigurator);
    function vaultManager() external view returns(IBotVaultManager);
    function addTemplate(address template) external;
    function templates() external view returns(address[] memory);
    function isRegisteredTemplate(address template) external view returns(bool);
    function isRegisteredBot(address botAccount) external view returns(bool);
    function totalBots() external view returns(uint);
    function botIdOf(string calldata qualifiedName) external view returns(int);
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output);
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external;
    function snapshot(address botAccount) external;
}