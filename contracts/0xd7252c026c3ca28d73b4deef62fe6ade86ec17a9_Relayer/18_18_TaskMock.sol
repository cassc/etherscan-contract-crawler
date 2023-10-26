// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TaskMock {
    event Succeeded();

    address public smartVault;

    constructor(address _smartVault) {
        smartVault = _smartVault;
    }

    function succeed() external returns (uint256) {
        emit Succeeded();
        return 1;
    }

    function fail() external pure {
        revert('TASK_FAILED');
    }
}