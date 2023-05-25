// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IAuthorizable {
    function addAuthorized(address _toAdd) external returns (bool);
    function removeAuthorized(address _toRemove) external returns (bool);
    function isAuthorized(address _auth) external view returns (bool);

    event Authorized(address indexed auth, bool isAuthorized);
}