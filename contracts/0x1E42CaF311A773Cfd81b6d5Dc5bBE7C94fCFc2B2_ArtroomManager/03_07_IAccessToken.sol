// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessToken {
    function mintAccess(
        address _to,
        uint256 _room_id
    ) external;
}