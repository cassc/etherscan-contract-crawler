// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokensRegistry {
    function isTokenWhitelisted(address token) external view returns (bool);
}