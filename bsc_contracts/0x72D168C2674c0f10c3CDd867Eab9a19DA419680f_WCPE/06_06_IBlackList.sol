// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlackList {
    function addBlackList(address _evilUser) external returns (bool);

    function removeBlackList(address _clearedUser) external returns (bool);

    function destroyBlackFunds(address _blackListedUser)
        external
        returns (bool);

    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);
}
