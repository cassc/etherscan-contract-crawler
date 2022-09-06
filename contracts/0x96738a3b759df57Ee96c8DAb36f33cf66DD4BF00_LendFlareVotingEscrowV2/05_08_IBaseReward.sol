// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IBaseReward {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;
    function addOwner(address _newOwner) external;
    function addOwners(address[] calldata _newOwners) external;
    function removeOwner(address _owner) external;
    function isOwner(address _owner) external view returns (bool);
}