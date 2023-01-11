// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../chainlink/AutomationCompatible.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IVoter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract EpochController is AutomationCompatibleInterface, OwnableUpgradeable  {

    address public automationRegistry;

    address public minter;
    address public voter;


    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
        minter = address(0x86069FEb223EE303085a1A505892c9D4BdBEE996);
        voter = address(0x62Ee96e6365ab515Ec647C065c2707d1122d7b26);
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
    }

    function setAutomationRegistry(address _automationRegistry) external onlyOwner {
        require(_automationRegistry != address(0));
        automationRegistry = _automationRegistry;
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function setMinter(address _minter ) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }



}