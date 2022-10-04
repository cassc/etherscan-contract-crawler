// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support and upgradeable trusted forwarder.
 */

abstract contract ERC2771Context_Upgradeable is Context {
  address private trustedForwarder;

  constructor(address _trustedForwarder) {
    trustedForwarder = _trustedForwarder;
  }

  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return forwarder == trustedForwarder;
  }

  function _upgradeTrustedForwarder(address _trustedForwarder) internal {
    trustedForwarder = _trustedForwarder;
  }

  function _msgSender() internal view virtual override returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}