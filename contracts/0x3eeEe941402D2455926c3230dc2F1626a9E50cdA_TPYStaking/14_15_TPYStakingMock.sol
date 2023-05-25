// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../TPYStaking.sol";

contract TPYStakingMock is TPYStaking {
    uint256 public mockTime;

    constructor(ERC20 token, address treasury, address admin) TPYStaking(token, treasury, admin) {}

    function setMockTime(uint256 time_) public returns (uint256) {
        mockTime = time_;
        return mockTime;
    }

    function getTime() internal view override returns (uint256) {
        return mockTime;
    }
}