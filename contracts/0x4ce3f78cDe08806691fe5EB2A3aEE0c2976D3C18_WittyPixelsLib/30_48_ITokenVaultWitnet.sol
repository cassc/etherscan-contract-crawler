// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenVault.sol";

abstract contract ITokenVaultWitnet
    is
        ITokenVault
{
    function cloneAndInitialize(bytes calldata) virtual external returns (ITokenVaultWitnet);
    function cloneDeterministicAndInitialize(bytes32, bytes calldata) virtual external returns (ITokenVaultWitnet);
}