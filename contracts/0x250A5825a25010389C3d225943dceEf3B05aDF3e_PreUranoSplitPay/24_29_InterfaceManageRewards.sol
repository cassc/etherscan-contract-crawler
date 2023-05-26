// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface InterfaceManageRewards {
    function listRegisteredRewardAddresses()
        external
        view
        returns (address[] memory);

    function getRewardByAddress(address _targetAddress)
        external
        view
        returns (uint16);

    function isRegisteredRewardAddress(address _rewardAddress)
        external
        view
        returns (bool);

    function getMainUsdRecipient() external view returns (address);
}