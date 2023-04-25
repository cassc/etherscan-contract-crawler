// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/AutomationCompatible.sol";
import "../dao/interfaces/IMinter.sol";
import "../dao/interfaces/IVoter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract EpochController is AutomationCompatibleInterface, OwnableUpgradeable  {

    address public automationRegistry;

    address public minter;
    address public voter;
    address public bluechipVoter;

    constructor() {}

    function initialize(
        address _minter,
        address _voter,
        address _bluechipVoter
    ) public initializer {
        __Ownable_init();
        minter = _minter;
        voter = _voter;
        bluechipVoter = _bluechipVoter;
        automationRegistry = address(0x02777053d6764996e594c3E88AF1D58D5363a2e6);
    }


    function checkUpkeep(bytes memory /*checkdata*/) public view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = IMinter(minter).check();
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(msg.sender == automationRegistry || msg.sender == owner(), 'cannot execute');
        (bool upkeepNeeded, ) = checkUpkeep('0');
        require(upkeepNeeded, "condition not met");
        IVoter(voter).distributeAll();
        IVoter(bluechipVoter).distributeAll();
    }

    function setAutomationRegistry(address _automationRegistry) external onlyOwner {
        require(_automationRegistry != address(0));
        automationRegistry = _automationRegistry;
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function setBluechipVoter(address _bluechipVoter) external onlyOwner {
        require(_bluechipVoter != address(0));
        bluechipVoter = _bluechipVoter;
    }

    function setMinter(address _minter ) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }

}