// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

interface IWhitelist {
    function isWhitelisted(address _account) external view returns (bool);
}