// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TimeLibrary {
    struct UserState {
        mapping(address => uint256) latestTimestamp;
    }

    function updateLatestTimestamp(UserState storage self) internal {
        self.latestTimestamp[msg.sender] = block.timestamp;
    }

    function getUserSecondsPassed(UserState storage self) internal view returns (uint256) {
        uint256 latest = self.latestTimestamp[msg.sender];
        return (block.timestamp - latest);
    }
}