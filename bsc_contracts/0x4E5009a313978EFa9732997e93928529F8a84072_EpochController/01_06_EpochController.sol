// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./chainlink/AutomationCompatible.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVoter.sol";


contract EpochController is AutomationCompatibleInterface  {

    address public automationRegistry;
    address public owner;

    address public condition;
    address public target;

    address[] public gauges;
    mapping(address => bool) public isGauge;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address _condition, address _target) {
        owner = msg.sender;
        condition = _condition;
        target = _target;
    }


    function checkUpkeep(bytes memory /*checkdata*/) public view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = IMinter(condition).check();
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(msg.sender == automationRegistry || msg.sender == owner, 'cannot execute');

        (bool upkeepNeeded, ) = checkUpkeep('0');
        require(upkeepNeeded, "condition not met");

        IVoter(target).distributeAll();
        IVoter(target).distributeFees(gauges);
    }

    function addGauge(address[] memory _gauges) external onlyOwner {
        uint i;
        address _gauge;
        for(i = 0; i < _gauges.length; i++){
            _gauge = _gauges[i];
            require(_gauge != address(0));
            if(isGauge[_gauge] == false){
                gauges.push(_gauge);
                isGauge[_gauge] = true;
            }
        }
    }


    function removeGauge(address[] memory _gauges) external onlyOwner {
        uint i;
        uint k;
        address _gauge;
        for(i = 0; i < _gauges.length; i++){
            _gauge = _gauges[i];
            if(isGauge[_gauge]){
                for(k=0; k < gauges.length; i++){
                    if(gauges[k] == _gauge) {
                        gauges[k] = gauges[gauges.length -1];
                        gauges.pop();
                        break;
                    }  
                }
            }

        }
    }

    function removeGaugeAt(uint _position) external onlyOwner {
        address _gauge= gauges[_position];

        //remove flag
        isGauge[_gauge] = false;

        //bring last to _pos and pop()
        gauges[_position] = gauges[gauges.length -1];
        gauges.pop();
        
    }

    function gaugesLength() public view returns(uint) {
        return gauges.length;
    }


    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
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