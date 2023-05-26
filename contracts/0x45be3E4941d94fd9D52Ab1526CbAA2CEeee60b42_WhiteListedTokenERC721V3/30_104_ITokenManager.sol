// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

interface ITokenManager {
    function setToken(address _token, bool _active) external;

    function removeToken(address _token) external;

    function supportToken(address _token) external view returns (bool);
}