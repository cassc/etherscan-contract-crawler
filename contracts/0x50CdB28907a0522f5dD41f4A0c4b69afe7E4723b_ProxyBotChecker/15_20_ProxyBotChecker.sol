// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IProxyBotChecker.sol" ;
import "./ProxyBot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title
 * Proxy Bot Checker
 * https://proxybot.turf.dev/
 *
 * @author
 * Turf NFT
 *
 * @notice
 * A Proxy for Proxy Bot
 * 
 * 3rd parties can use this contract (and its interface) to interact with 
 * the important Proxy Bot method.
 *
 * See the full Proxy Bot contract for more details.
 *
 */

contract ProxyBotChecker is IProxyBotChecker, AccessControl {

  address payable public proxyBot;
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");  

  error NotAnAdminError();

  constructor(address payable _proxyBot) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    proxyBot = _proxyBot;
  }

  modifier onlyAdmin() {
    if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(ADMIN_ROLE, msg.sender)){
      revert NotAnAdminError();
    }
    _;
  }

  /**
  * @notice
  * Given a hot wallet's address, returns the address of the vault it proxies to,
  * if any active connections exist.
  * 
  * This is the method to call off-chain for proxy access purposes.
  * 
  * @param delegateAddress The address to check.
  * @return The address of the vault that the given address proxies to, or a zero address if none exists.
  */
  function getVaultAddressForDelegate(address delegateAddress) external view returns (address) {
    return ProxyBot(proxyBot).getVaultAddressForDelegate(delegateAddress);
  }

  function setProxyBot(address payable _proxyBot) external onlyAdmin {
    proxyBot = _proxyBot;
  }
}