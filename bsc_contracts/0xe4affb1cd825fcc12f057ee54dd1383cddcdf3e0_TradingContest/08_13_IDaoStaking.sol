// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IDaoStaking {
    function userInfo(address _user) external view returns (uint256, uint256, uint256);
}