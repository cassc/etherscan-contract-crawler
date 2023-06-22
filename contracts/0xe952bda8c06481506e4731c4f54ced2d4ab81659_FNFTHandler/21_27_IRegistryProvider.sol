// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILockManager.sol";
import "../interfaces/ITokenVault.sol";
import "../lib/uniswap/IUniswapV2Factory.sol";

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
}