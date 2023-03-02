// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface INetGymStreet {
    function getUserCurrentLevel(address _user) external view returns (uint256);
    function seedUserMlmLevel(address _user, address _oldAddr, bool _isNewPurchaseDate) external;
    function userLevel(address _user) external view returns (uint256);
}