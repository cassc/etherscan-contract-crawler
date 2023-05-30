// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBentStaking {
    function depositFor(address _user, uint256 _amount) external;

    function withdrawTo(address _recipient, uint256 _amount) external;

    function claimAllFor(address _user) external;
}