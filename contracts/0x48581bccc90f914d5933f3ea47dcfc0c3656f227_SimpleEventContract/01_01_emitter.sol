// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SimpleEventContract {
    
    // Define an event that will be emitted whenever a value is logged.
    event ValueEmitted(uint256 value);

    // Function to emit the value.
    function emitValue(uint256 _value) public {
        emit ValueEmitted(_value);
    }
}