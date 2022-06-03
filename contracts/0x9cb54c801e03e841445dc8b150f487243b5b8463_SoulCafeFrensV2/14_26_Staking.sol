// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../staking/StakingCommons.sol";

library AutoStaking {
    function arrayify(uint256 value) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = value;
        return array;
    }

    function arrayify(StakeAction value) internal pure returns (StakeAction[] memory) {
        StakeAction[] memory array = new StakeAction[](1);
        array[0] = value;
        return array;
    }

    function arrayify(StakeRequest memory value) internal pure returns (StakeRequest[] memory) {
        StakeRequest[] memory array = new StakeRequest[](1);
        array[0] = value;
        return array;
    }
}