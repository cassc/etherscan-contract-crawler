/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface IReferralProgram {
    function getReferralINSURRewardPctg(uint256 rewardType) external view returns (uint256);

    function setReferralINSURRewardPctg(uint256 rewardType, uint256 percent) external;

    function getReferralINSURRewardAmount() external view returns (uint256);

    function getTotalReferralINSURRewardAmount() external view returns (uint256);

    function getRewardPctg(uint256 rewardType, uint256 overwrittenRewardPctg) external view returns (uint256);

    function getRewardAmount(
        uint256 rewardType,
        uint256 baseAmount,
        uint256 overwrittenRewardPctg
    ) external view returns (uint256);

    function processReferralReward(
        address referrer,
        address referee,
        uint256 rewardType,
        uint256 baseAmount,
        uint256 rewardPctg
    ) external;

    function unlockRewardByController(address referrer, address to) external returns (uint256);

    function getINSURRewardBalanceDetails() external view returns (uint256, uint256);

    function removeINSURRewardBalance(address toAddress, uint256 amount) external;
}