// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxyRegistry {
    function proxies(address account) external view returns (address);

    function contracts(address caller) external view returns (bool);
}

interface IAuthenticatedProxy {
    function user() external view returns (address);
}