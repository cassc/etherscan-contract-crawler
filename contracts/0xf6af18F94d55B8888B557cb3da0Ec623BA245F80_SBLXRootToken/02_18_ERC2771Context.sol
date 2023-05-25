// SPDX-License-Identifier: NONE
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Context variant with ERC2771 support that supports multiple trusted
 * forwarders. This is a modified version of Openzeppelin's ERC2771Context.sol.
 */
abstract contract ERC2771Context is Context, AccessControl {
    mapping(address => bool) private _trustedForwarders;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders[forwarder];
    }

    function addTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
      _trustedForwarders[forwarder] = true;
    }

    function removeTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
      delete(_trustedForwarders[forwarder]);
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