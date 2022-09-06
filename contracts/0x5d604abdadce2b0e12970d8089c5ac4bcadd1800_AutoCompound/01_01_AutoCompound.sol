// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract AutoCompound {
    mapping(address => bool) private isAutoCompoundOff; // interpret 0 as ON, to use default values more efficiently. Use normal mapping true=>ON everywhere outside this map.


    function setStrategy(bool _isAutoCompoundOn) external {
        if (isAutoCompoundOff[msg.sender] == _isAutoCompoundOn) {
            isAutoCompoundOff[msg.sender] = !_isAutoCompoundOn;
        }
    }

    function getStrategy(address _user) external view returns(bool) {
        return !isAutoCompoundOff[_user];
    }
}