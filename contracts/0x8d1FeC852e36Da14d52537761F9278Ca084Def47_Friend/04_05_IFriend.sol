// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IFriend {
    function isFriend(address alice, address bob) external view returns (bool);
}