pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

contract StakeHouseRegistry {

    function transferOwnership(address) external {}

    address public keeper;
    function setGateKeeper(address _keeper) external {
        keeper = _keeper;
    }

}