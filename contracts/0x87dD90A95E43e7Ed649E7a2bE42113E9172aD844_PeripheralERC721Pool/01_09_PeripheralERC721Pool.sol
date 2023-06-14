// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPeripheralERC721Pool.sol";
import "./IERC721Pool.sol";

/// @title PeripheralERC721Pool
/// @author Hifi
contract PeripheralERC721Pool is IPeripheralERC721Pool {
    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IPeripheralERC721Pool
    function bulkDeposit(IERC721Pool pool, uint256[] calldata ids) external override {
        // Checks: ids length must be greater than zero
        if (ids.length == 0) {
            revert PeripheralERC721Pool__InsufficientIn();
        }

        IERC721 erc721Asset = IERC721(pool.asset());

        // Effects: Approve the pool to transfer the NFTs.
        if (!erc721Asset.isApprovedForAll(address(this), address(pool)))
            erc721Asset.setApprovalForAll(address(pool), true);

        // `msg.sender` is the owner of the NFTs who will receive the pool tokens.
        for (uint256 i = 0; i < ids.length; ) {
            // Interactions: Transfer the NFTs from caller to this contract.
            // The transfer will revert if this contract is not approved to transfer the NFT.
            erc721Asset.transferFrom(msg.sender, address(this), ids[i]);

            // Effects: transfer NFTs from this contract to the pool and mint pool tokens to msg.sender.
            pool.deposit(ids[i], msg.sender);
            unchecked {
                ++i;
            }
        }

        emit BulkDeposit(address(pool), ids, msg.sender);
    }

    /// @inheritdoc IPeripheralERC721Pool
    function bulkWithdraw(IERC721Pool pool, uint256[] calldata ids) public override {
        uint256 idsLength = ids.length;

        withdrawInternal(pool, idsLength);

        for (uint256 i = 0; i < idsLength; ) {
            // `msg.sender` is the owner of the pool tokens who will receive the NFTs.
            // Effects: transfer NFTs from the pool to msg.sender in exchange for pool tokens.
            pool.withdraw(ids[i], msg.sender);
            unchecked {
                ++i;
            }
        }
        emit BulkWithdraw(address(pool), ids, msg.sender);
    }

    /// @inheritdoc IPeripheralERC721Pool
    function withdrawAvailable(IERC721Pool pool, uint256[] calldata ids) external override {
        uint256 idsLength = ids.length;

        withdrawInternal(pool, idsLength);

        uint256[] memory withdrawnIds = new uint256[](idsLength);
        uint256 withdrawnCount;
        for (uint256 i; i < idsLength; ) {
            // `msg.sender` is the owner of the pool tokens who will receive the NFTs.
            // Effects: transfer available NFTs from the pool to msg.sender in exchange for pool tokens
            if (pool.holdingContains(ids[i])) {
                pool.withdraw(ids[i], msg.sender);
                withdrawnIds[withdrawnCount] = ids[i];
                withdrawnCount++;
            }
            unchecked {
                ++i;
            }
        }

        if (withdrawnCount == 0) {
            revert PeripheralERC721Pool__NoNFTsWithdrawn();
        }

        // Resize the withdrawnIds array to fit the actual number of withdrawn NFTs
        assembly {
            mstore(withdrawnIds, withdrawnCount)
        }
        pool.transfer(msg.sender, (idsLength - withdrawnCount) * 10**18);
        emit WithdrawAvailable(address(pool), withdrawnIds, msg.sender);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function withdrawInternal(IERC721Pool pool, uint256 idsLength) internal {
        // Checks: ids length must be greater than zero
        if (idsLength == 0) {
            revert PeripheralERC721Pool__InsufficientIn();
        }

        // Checks: The caller must have allowed this contract to transfer the pool tokens.
        if (pool.allowance(msg.sender, address(this)) < idsLength * 10**18)
            revert PeripheralERC721Pool__UnapprovedOperator();

        // Interactions: Transfer the pool token from caller to this contract.
        pool.transferFrom(msg.sender, address(this), idsLength * 10**18);
    }
}