// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyCaller.sol";

interface IProxyOwner {
    function acquireProxy() external returns (ProxyCaller);

    function releaseProxy(ProxyCaller proxy) external;

    function proxyExec(
        ProxyCaller proxy,
        bool delegate,
        address target,
        bytes calldata data
    ) external returns (bool success, bytes memory);

    function proxyTransfer(
        ProxyCaller proxy,
        address target,
        uint256 amount
    ) external returns (bool success, bytes memory);
}