// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Factory} from "@rainprotocol/rain-protocol/contracts/factory/Factory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {Receipt} from "./Receipt.sol";

/// @title ReceiptFactory
/// @notice Factory that builds `Receipt` children and is ostensibly used by the
/// `ReceiptVaultFactory` so ownership assignment MUST be handled by the caller
/// of `createChild`.
contract ReceiptFactory is Factory {
    /// Implementation address that will be cloned when creating child contracts.
    address public immutable implementation;

    /// Builds the `Receipt` reference implementation that all children will be
    /// a proxy to.
    constructor() {
        address implementation_ = address(new Receipt());
        implementation = implementation_;
        emit Implementation(msg.sender, implementation_);
    }

    /// The owner is `msg.sender` because this is intended to be used by the
    /// `ReceiptVaultFactory` which will subsequently and atomically assign
    /// ownership to the `ReceiptVault` that it creates.
    /// @inheritdoc Factory
    function _createChild(
        bytes memory
    ) internal virtual override returns (address) {
        address clone_ = Clones.clone(implementation);
        Receipt(clone_).initialize();
        Receipt(clone_).transferOwnership(msg.sender);
        return clone_;
    }
}