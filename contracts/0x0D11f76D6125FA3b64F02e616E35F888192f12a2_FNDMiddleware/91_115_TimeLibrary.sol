// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/libraries/TimeLibrary.sol";

contract $TimeLibrary {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $hasExpired(uint256 expiry) external view returns (bool) {
        return TimeLibrary.hasExpired(expiry);
    }

    function $hasBeenReached(uint256 timestamp) external view returns (bool) {
        return TimeLibrary.hasBeenReached(timestamp);
    }

    receive() external payable {}
}