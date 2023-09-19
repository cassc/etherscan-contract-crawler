/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3UserQuota {
    function getUserQuota(address user, address token) external view returns (uint256);
    function checkQuota(address user, address token, uint256 amount) external view returns (bool);
}