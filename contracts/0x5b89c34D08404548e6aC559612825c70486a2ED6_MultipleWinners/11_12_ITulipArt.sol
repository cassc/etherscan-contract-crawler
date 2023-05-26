// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

interface ITulipArt {
    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function setWinner(address _winner) external;

    function startDraw() external;

    function finishDraw() external;

    function chanceOf(address user) external view returns (uint256);

    function userStake(address user) external view returns (uint256);

    function draw(uint256 randomNumber) external view returns (address);
}