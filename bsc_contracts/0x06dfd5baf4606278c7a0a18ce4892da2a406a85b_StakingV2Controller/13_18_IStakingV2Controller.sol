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

interface IStakingV2Controller {
    function stakeTokens(uint256 _amount, address _token) external payable;

    function proposeUnstake(uint256 _amount, address _token) external;

    function withdrawTokens(
        address _caller,
        address payable _staker,
        uint256 _amount,
        address _token,
        uint256 _nonce,
        uint256 _deadline,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function unlockRewardsFromPoolsByController(
        address staker,
        address _to,
        address[] memory _tokenList
    ) external returns (uint256);

    function showRewardsFromPools(address[] memory _tokenList) external view returns (uint256);

    function showRewardsFromPoolsByStaker(address staker, address[] memory _tokenList) external view returns (uint256);
}