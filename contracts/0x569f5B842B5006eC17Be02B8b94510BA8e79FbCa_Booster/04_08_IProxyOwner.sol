// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProxyOwner {
    function proxyToggleStaker(address _vault) external;
}