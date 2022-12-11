// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support
 */

// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
  /**
   * @dev holds the trust forwarder
   */

  address public trustedForwarder;

  /**
   * @dev context upgradeable initializer
   * @param _trustedForwarder trust forwarder
   */

  function __ERC2771ContextUpgradeable_init(address _trustedForwarder) internal onlyInitializing {
    __ERC2771ContextUpgradeable_init_unchained(_trustedForwarder);
  }

  /**
   * @dev called by initializer to set trust forwarder
   * @param _trustedForwarder trust forwarder
   */

  function __ERC2771ContextUpgradeable_init_unchained(address _trustedForwarder) internal {
    trustedForwarder = _trustedForwarder;
  }

  /**
   * @dev check if the given address is trust forwarder
   * @param forwarder forwarder address
   * @return isForwarder true/false
   */

  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return forwarder == trustedForwarder;
  }

  /**
   * @dev if caller is trusted forwarder will return exact sender.
   * @return sender wallet address
   */

  function _msgSender() internal view virtual returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return msg.sender;
    }
  }

  /**
   * @dev returns msg data for called function
   * @return function call data
   */

  function _msgData() internal view virtual returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return msg.data;
    }
  }
}