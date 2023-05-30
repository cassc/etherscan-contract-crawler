// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAllowsProxy {
    function isProxyActive() external view returns (bool);

    function proxyAddress() external view returns (address);

    function isApprovedForProxy(address _owner, address _operator)
        external
        view
        returns (bool);
}