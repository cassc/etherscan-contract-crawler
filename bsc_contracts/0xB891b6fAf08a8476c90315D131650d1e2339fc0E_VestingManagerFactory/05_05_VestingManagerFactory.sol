// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./VestingManager.sol";

contract VestingManagerFactory is Ownable {

    address public last;

    function createVestingManager() external onlyOwner returns (address) {
        VestingManager vestingManager = new VestingManager();
        last = address(vestingManager);
        return last;
    }

}