// SPDX-License-Identifier: LGPL-3.0-only
// Source: https://github.com/gnosis/zodiac/blob/master/contracts/factory/ModuleProxyFactory.sol
pragma solidity 0.8.13;

interface IModuleProxyFactory {
  function deployModule(
    address masterCopy,
    bytes memory initializer,
    uint256 saltNonce
  ) external returns (address proxy);
}