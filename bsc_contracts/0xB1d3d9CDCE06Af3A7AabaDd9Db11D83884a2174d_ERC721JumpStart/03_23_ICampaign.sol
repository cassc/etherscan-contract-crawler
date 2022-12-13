// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICampaign {

    function completeCampaign() external;

    function claimRefund() external;

    function updateUserContributed(address _user, uint256 _amount) external;

    function getDates() external view returns (uint256, uint256, bool);
}