// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./interfaces/IVanillaV1Safelist01.sol";

/// @title The contract that keeps a safelist of rewardable ERC-20 tokens and next approved Vanilla version
contract VanillaV1Safelist01 is IVanillaV1Safelist01 {

    address private immutable owner;
    /// @inheritdoc IVanillaV1Safelist01
    mapping(address => bool) public override isSafelisted;

    /// @inheritdoc IVanillaV1Safelist01
    address public override nextVersion;

    constructor(address safeListOwner) {
        owner = safeListOwner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    /// @notice Adds and removes tokens to/from the safelist. Only for the owner.
    /// @dev Adds first and removes second, so adding and removing a token will not result in safelisted token
    /// @param added Array of added ERC-20 addresses
    /// @param removed Array of removed ERC-20 addresses
    function modify(address[] calldata added, address[] calldata removed) external onlyOwner {
        uint numAdded = added.length;
        if (numAdded > 0) {
            for (uint i = 0; i < numAdded; i++) {
                isSafelisted[added[i]] = true;
            }
            emit TokensAdded(added);
        }

        uint numRemoved = removed.length;
        if (numRemoved > 0) {
            for (uint i = 0; i < numRemoved; i++) {
                delete isSafelisted[removed[i]];
            }
            emit TokensRemoved(removed);
        }
    }

    /// @notice Approves the next version implementation. Only for the owner.
    /// @param implementation Address of the IVanillaV1MigrationTarget02 implementation
    function approveNextVersion(address implementation) external onlyOwner {
        nextVersion = implementation;
    }

}