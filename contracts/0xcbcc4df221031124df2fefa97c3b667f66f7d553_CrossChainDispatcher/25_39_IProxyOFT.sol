// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@layerzerolabs/solidity-examples/contracts-upgradeable/token/oft/composable/IComposableOFTCoreUpgradeable.sol";

interface IProxyOFT is IComposableOFTCoreUpgradeable {
    function getProxyOFTOf(uint16 chainId_) external view returns (address _proxyOFT);
}