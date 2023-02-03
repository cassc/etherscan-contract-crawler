// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface INetGymStreet {
    function addGymMlm(address _user, uint256 _referrerId) external;

    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user
    ) external;

    function getUserCurrentLevel(address _user) external view returns (uint256);

    function updateAdditionalLevel(address _user, uint256 _level) external;
    function getInfoForAdditionalLevel(address _user) external view returns (uint256 _termsTimestamp, uint256 _level);

    function lastPurchaseDateERC(address _user) external view returns (uint256);
}