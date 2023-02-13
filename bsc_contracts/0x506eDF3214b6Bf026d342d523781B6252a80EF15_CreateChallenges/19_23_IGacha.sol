// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IGacha {
    /**
     * @notice send daily result with gacha
     * @return true: ramdom success
     * false: ramdom failed
     */
    function randomRewards(uint256[] memory _listIndexReward, address _challengerAddress) external returns(bool);
}