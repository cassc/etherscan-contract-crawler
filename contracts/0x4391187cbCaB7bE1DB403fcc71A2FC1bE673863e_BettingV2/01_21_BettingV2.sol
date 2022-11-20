// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Betting.sol";

contract BettingV2 is Betting {
    function getUserBets(address userAddress_, uint256 poolId_) external view returns (uint256[] memory) {
        return userBets[poolId_][userAddress_];
    }
}