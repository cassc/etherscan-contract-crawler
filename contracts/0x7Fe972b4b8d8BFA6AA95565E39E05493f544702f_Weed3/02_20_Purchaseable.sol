// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// @author rollauver.eth

abstract contract Purchaseable is Ownable, Pausable {
  function purchaseHelper(address to, uint256 count)
    internal virtual;

  function earlyPurchaseHelper(address to, uint256 count)
    internal virtual;

  function isPreSaleActive() public view virtual returns (bool);

  function isPublicSaleActive() public view virtual returns (bool);
}