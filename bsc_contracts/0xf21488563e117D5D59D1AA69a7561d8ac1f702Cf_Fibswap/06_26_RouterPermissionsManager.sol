// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {RouterPermissionsLogic, RouterPermissionsInfo} from "./lib/Fibswap/RouterPermissionsLogic.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice
 * This contract is designed to manage router access, meaning it maintains the
 * router recipients, owners, and the router whitelist itself. It does *not* manage router balances
 * as asset management is out of scope of this contract.
 *
 * As a router, there are three important permissions:
 * `router` - this is the address that will sign bids sent to the sequencer
 * `routerRecipient` - this is the address that receives funds when liquidity is withdrawn
 * `routerOwner` - this is the address permitted to update recipients and propose new owners
 *
 * In cases where the owner is not set, the caller should be the `router` itself. In cases where the
 * `routerRecipient` is not set, the funds can be removed to anywhere.
 *
 * When setting a new `routerOwner`, the current owner (or router) must create a proposal, which
 * can be accepted by the proposed owner after the delay period. If the proposed owner is the empty
 * address, then it must be accepted by the current owner.
 */
abstract contract RouterPermissionsManager is Initializable {
  // ============ Private storage =============

  uint256 private _delay;

  // ============ Public Storage =============

  RouterPermissionsInfo internal routerInfo;

  // ============ Initialize =============

  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __RouterPermissionsManager_init() internal onlyInitializing {
    __RouterPermissionsManager_init_unchained();
  }

  function __RouterPermissionsManager_init_unchained() internal onlyInitializing {
    _delay = 7 days;
  }

  // ============ Public methods =============

  function approvedRouters(address _router) public view returns (bool) {
    return routerInfo.approvedRouters[_router];
  }

  function routerRecipients(address _router) public view returns (address) {
    return routerInfo.routerRecipients[_router] == address(0) ? _router : routerInfo.routerRecipients[_router];
  }

  function routerOwners(address _router) public view returns (address) {
    return routerInfo.routerOwners[_router] == address(0) ? _router : routerInfo.routerOwners[_router];
  }

  /**
   * @notice Sets the designated recipient for a router
   * @dev Router should only be able to set this once otherwise if router key compromised,
   * no problem is solved since attacker could just update recipient
   * @param router Router address to set recipient
   * @param recipient Recipient Address to set to router
   */
  function setRouterRecipient(address router, address recipient) external {
    RouterPermissionsLogic.setRouterRecipient(router, recipient, routerInfo);
  }

  /**
   * @notice Current owner or router may propose a new router owner
   * @param router Router address to set recipient
   * @param owner Proposed owner Address to set to router
   */
  function setRouterOwner(address router, address owner) external {
    RouterPermissionsLogic.setRouterOwner(router, owner, routerInfo);
  }

  // ============ Private methods =============

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function _setupRouter(
    address router,
    address owner,
    address recipient
  ) internal {
    RouterPermissionsLogic.setupRouter(router, owner, recipient, routerInfo);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function _removeRouter(address router) internal {
    RouterPermissionsLogic.removeRouter(router, routerInfo);
  }
}