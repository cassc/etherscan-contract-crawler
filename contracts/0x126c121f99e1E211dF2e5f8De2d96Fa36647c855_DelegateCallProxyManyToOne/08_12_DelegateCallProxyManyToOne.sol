// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Proxy contract which uses an implementation address shared with many
 * other proxies.
 *
 * An implementation holder contract stores the upgradeable implementation address.
 * When the proxy is called, it queries the implementation address from the holder
 * contract and delegatecalls the returned address, forwarding the received calldata
 * and ether.
 *
 * Note: This contract does not verify that the implementation
 * address is a valid delegation target. The manager must perform
 * this safety check before updating the implementation on the holder.
 */
contract DelegateCallProxyManyToOne is Proxy {
/* ==========  Constants  ========== */

  // Address that stores the implementation address.
  address internal immutable _implementationHolder;

/* ==========  Constructor  ========== */

  constructor() public {
    // Calls the sender rather than receiving the address in the constructor
    // arguments so that the address is computable using create2.
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Queries the implementation address from the implementation holder.
   */
  function _implementation() internal override view returns (address) {
    // Queries the implementation address from the implementation holder.
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}