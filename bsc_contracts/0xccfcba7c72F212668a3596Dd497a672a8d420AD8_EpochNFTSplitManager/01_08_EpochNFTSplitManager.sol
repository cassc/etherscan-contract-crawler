// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AutomationCompatible.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
interface ICondition {
    function check() external view returns(bool);
}

interface ITarget {
    function performUpkeep() external;
}

contract EpochNFTSplitManager is AutomationCompatibleInterface, OwnableUpgradeable  {

    address public automationRegistry;

    address public condition;
    address public target;

    address[] public gauges;
    mapping(address => bool) public isGauge;

    constructor() {}

    function initialize(address _condition, address _target) initializer  public {
        __Ownable_init();
        condition = _condition;
        target = _target;
    }


    function checkUpkeep(bytes memory /*checkdata*/) public view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = ICondition(condition).check();
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(msg.sender == automationRegistry || msg.sender == owner(), 'cannot execute');
        ITarget(target).performUpkeep();        
    }

    function setAutomationRegistry(address _automationRegistry) external onlyOwner {
        require(_automationRegistry != address(0));
        automationRegistry = _automationRegistry;
    }

    function setTarget(address _target) external onlyOwner {
        require(_target != address(0));
        target = _target;
    }

    function setCondition(address _condition ) external onlyOwner {
        require(_condition != address(0));
        condition = _condition;
    }



}