// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title Admin of the proxy contract
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract QuantumProxyAdmin is ProxyAdmin {

}