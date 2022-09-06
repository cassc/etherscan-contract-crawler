// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IAuthenticatedProxy} from "./IAuthenticatedProxy.sol";

interface IAuthorizationManager {
    function revoked() external returns (bool);

    function authorizedAddress() external returns (address);

    function proxies(address owner) external returns (address);

    function revoke() external;

    function registerProxy() external returns (address);
}