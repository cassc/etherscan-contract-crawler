// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IBlockListRegistry} from "./IBlockListRegistry.sol";

/// @title BlockAllRegistry
/// @notice BlockList that blocks all approvals
///     can be used as a semi-soulbound token
/// @author transientlabs.xyz
/// @custom:version 4.1.0
contract BlockAllRegistry is IBlockListRegistry {
    
    /// @inheritdoc IBlockListRegistry
    function getBlockListStatus(address /*operator*/) external pure override returns(bool) {
        return true;
    }

    /// @inheritdoc IBlockListRegistry
    function setBlockListStatus(address[] calldata /*operators*/, bool /*status*/) external pure override {
        revert();
    }

    /// @inheritdoc IBlockListRegistry
    function clearBlockList() external pure override {
        revert();
    }

}