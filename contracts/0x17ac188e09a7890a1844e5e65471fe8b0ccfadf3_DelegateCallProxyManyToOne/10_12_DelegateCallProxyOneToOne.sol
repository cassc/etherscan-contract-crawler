// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Upgradeable delegatecall proxy for a single contract.
 *
 * This proxy stores an implementation address which can be upgraded by the proxy manager.
 *
 * To upgrade the implementation, the manager calls the proxy with the abi encoded implementation address.
 *
 * If any other account calls the proxy, it will delegatecall the implementation address with the received
 * calldata and ether. If the call succeeds, it will return with the received returndata.
 * If it reverts, it will revert with the received revert data.
 *
 * Note: The storage slot for the implementation address is:
 * `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`
 * This slot must not be used by the implementation contract.
 *
 * Note: This contract does not verify that the implementation address is a valid delegation target.
 * The manager must perform this safety check.
 */
contract DelegateCallProxyOneToOne is Proxy {
/* ==========  Constants  ========== */
  address internal immutable _manager;

/* ==========  Constructor  ========== */
  constructor() public {
    _manager = msg.sender ;
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Reads the implementation address from storage.
   */
  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  /**
    * @dev Hook that is called before falling back to the implementation.
    *
    * Checks if the call is from the owner.
    * If it is, reads the abi-encoded implementation address from calldata and stores
    * it at the slot `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`,
    * then returns with no data.
    * If it is not, continues execution with the fallback function.
    */
  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}