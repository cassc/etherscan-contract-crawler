// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "src/VaultERC20.sol";
import "src/VaultERC721.sol";
import "src/VaultETH.sol";
import "src/VaultExecute.sol";
import "src/VaultNewReceivers.sol";
import "src/VaultIssueERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Vault is
  Initializable,
  VaultERC20,
  VaultERC721,
  VaultETH,
  VaultExecute,
  VaultNewReceivers,
  VaultIssueERC721
{
  function initialize() initializer public {
    __initializeERC20(1, 2, 11);
    __initializeERC721(3);
    __initializeETH(4, 5);
    __initializeExecute(6, 7);
    __initializeNewReceivers(8);
    __initializeIssueERC721(9);
    __initializePausable(10);
  }
}