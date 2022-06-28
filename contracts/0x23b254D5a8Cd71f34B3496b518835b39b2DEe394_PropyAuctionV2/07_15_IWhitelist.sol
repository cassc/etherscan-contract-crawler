// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IWhitelist {
    function whitelist(address _user) external view returns (bool);
}