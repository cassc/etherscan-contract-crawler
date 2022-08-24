// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IAuthorizationManager {
    function authorizedAddress() external view returns (address);

    function proxies(address owner) external view returns (address);

    function revoked() external view returns (bool);

    function revoke() external;

    function registerProxy() external returns (address);
}