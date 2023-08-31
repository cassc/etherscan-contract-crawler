// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "../ERC-721/IERC721PoolFactory.sol";
import "./IV2Migrator.sol";

/// @title V2Migrator
/// @author Hifi
contract V2Migrator is IV2Migrator {
    IERC721PoolFactoryV1 public v1PoolFactory;
    IERC721PoolFactory public v2PoolFactory;

    /// CONSTRUCTOR ///

    constructor(address _v1PoolFactoryAddress, address _v2PoolFactoryAddress) {
        v1PoolFactory = IERC721PoolFactoryV1(_v1PoolFactoryAddress);
        v2PoolFactory = IERC721PoolFactory(_v2PoolFactoryAddress);
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IV2Migrator
    function migrate(address asset, uint256[] calldata ids) external override {
        address v1PoolAddress = v1PoolFactory.getPool(asset);
        address v2PoolAddress = v2PoolFactory.getPool(asset);

        // Checks: v1 pool must exist
        if (v1PoolAddress == address(0)) {
            revert V2Migrator__V1PoolDoesNotExist();
        }

        // Checks: v2 pool must exist
        if (v2PoolAddress == address(0)) {
            revert V2Migrator__V2PoolDoesNotExist();
        }

        // Checks: ids length must be greater than zero
        if (ids.length == 0) {
            revert V2Migrator__InsufficientIn();
        }

        // Checks: The caller must have allowed this contract to transfer the pool tokens.
        if (IERC20Wnft(v1PoolAddress).allowance(msg.sender, address(this)) < ids.length * 10**18) {
            revert V2Migrator__UnapprovedOperator();
        }

        // Interactions: Transfer the pool token from caller to this contract.
        IERC20Wnft(v1PoolAddress).transferFrom(msg.sender, address(this), ids.length * 10**18);

        // Effects: withdraw NFTs from the V1 pool and burn pool tokens from msg.sender.
        IERC721PoolV1(v1PoolAddress).withdraw(ids);

        IERC721Pool v2Pool = IERC721Pool(v2PoolAddress);

        // Effects: Approve the v2 pool to transfer the NFTs.
        if (!IERC721(asset).isApprovedForAll(address(this), v2PoolAddress)) {
            IERC721(asset).setApprovalForAll(v2PoolAddress, true);
        }

        for (uint256 i = 0; i < ids.length; ) {
            // Effects: transfer NFTs from this contract to the pool and mint pool tokens to msg.sender.
            v2Pool.deposit(ids[i], msg.sender);
            unchecked {
                ++i;
            }
        }

        emit Migrate(asset, msg.sender, ids);
    }
}