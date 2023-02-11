// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface INetGymStreet {
    function getUserCurrentLevel(address _user) external view returns (uint256);
    function seedUserMlmLevel(address _user, uint256 _level, bool _isNewPurchaseDate) external;
}