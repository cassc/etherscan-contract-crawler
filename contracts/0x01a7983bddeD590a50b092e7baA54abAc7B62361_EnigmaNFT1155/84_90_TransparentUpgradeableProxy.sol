// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

// Importing this file so it get compiled and get the artifact to deploy
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/// @title TransparentUpgradeableProxy
///
/// @dev This contract implements the transparent proxy by openZeppelin that is upgradeable by an admin.
///         The proxy admin can update the implementation logic