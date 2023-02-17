// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;


abstract contract Timelock {

    uint256 constant public UNSET_TIMESTAMP = 1;
    bytes constant public UNSET_VALUE = new bytes(0x01); 

    uint256 public delay;
    mapping(bytes32 => TimelockData) public timelockData;

    struct TimelockData {
        uint256 timestamp;
        bytes value;
    }
    
    error NoTimelock();
    error Wait();

    // @notice Internal function to initiate a timelock
    // @param key The bytes32 key that represents the function that is timelocked
    // @param value The bytes value that is stored until the timelock completes
    function _startTimelock(bytes32 key, bytes memory value) internal {
        TimelockData storage td = timelockData[key]; 
        td.timestamp = block.timestamp;
        td.value = value;
    }

    // @notice Internal function to check the current status of a timelock and revert if the timelock has not matured
    // @param key The bytes32 key that represents the function that is timelocked
    function _checkTimelock(bytes32 key) internal view {
        TimelockData memory td = timelockData[key]; 
        if (td.timestamp < 2) revert NoTimelock();
        if (block.timestamp < td.timestamp + delay) revert Wait();
    }

    // @notice Internal function to view the value stored for a timelock
    // @return The bytes value that is stored until the timelock completes
    function _getTimelockValue(bytes32 key) internal view returns(bytes memory) {
        return timelockData[key].value; 
    }

    // @notice Reset the timelock
    // @param key The bytes32 key that represents the function that is timelocked
    function _resetTimelock(bytes32 key) internal {
        TimelockData storage td = timelockData[key];
        // By not deleting TimelockData, we save gas on subsequent actions
        td.timestamp = UNSET_TIMESTAMP; 
        td.value = UNSET_VALUE;
    }
}