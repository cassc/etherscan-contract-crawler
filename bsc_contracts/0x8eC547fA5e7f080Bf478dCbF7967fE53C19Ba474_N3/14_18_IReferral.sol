// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferral {
    function recordReferral(address _user,  string memory code) external;

    function onTransfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _transferType
    ) external;

    function addReward(address _user, uint256 _rewardAmount) external;

    function setReferrer(string memory code) external;

    function getReferrer(address _user) external view returns (address);
}