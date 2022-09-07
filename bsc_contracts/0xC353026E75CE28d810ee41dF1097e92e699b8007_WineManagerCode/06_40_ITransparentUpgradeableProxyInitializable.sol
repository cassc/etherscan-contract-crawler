// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITransparentUpgradeableProxyInitializable
{
    function initializeProxy(
        address _logic,
        address admin_,
        bytes memory _data
    ) external;
}