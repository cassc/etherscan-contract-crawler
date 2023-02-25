// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Copied and modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/ERC2771Context.sol (MIT licensed)
 */
abstract contract ERC2771Context is SafeAware {
    // SAFE_SLOT = keccak256("firm.erc2271context.forwarders") - 1
    bytes32 internal constant ERC2271_TRUSTED_FORWARDERS_BASE_SLOT =
        0xde1482070091aef895249374204bcae0fa9723215fa9357228aa489f9d1bd669;

    event TrustedForwarderSet(address indexed forwarder, bool enabled);

    function setTrustedForwarder(address forwarder, bool enabled) external onlySafe {
        _setTrustedForwarder(forwarder, enabled);
    }

    function _setTrustedForwarder(address forwarder, bool enabled) internal {
        _trustedForwarders()[forwarder] = enabled;

        emit TrustedForwarderSet(forwarder, enabled);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders()[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _trustedForwarders() internal pure returns (mapping(address => bool) storage trustedForwarders) {
        assembly {
            trustedForwarders.slot := ERC2271_TRUSTED_FORWARDERS_BASE_SLOT
        }
    }
}