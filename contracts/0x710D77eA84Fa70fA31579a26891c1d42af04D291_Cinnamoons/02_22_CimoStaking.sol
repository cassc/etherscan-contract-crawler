// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./../interfaces/ICimoStaking.sol";

abstract contract CimoStaking is ICimoStaking {
        mapping(uint256 => mapping(address => UserInfo)) public userInfo;
}