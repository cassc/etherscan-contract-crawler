// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "./ERC1155Permit.sol";
import "../base/ManagerBase.sol";
import "../interfaces/IPositionDescriptor.sol";

/// @title   PositionManager contract
/// @author  Primitive
/// @notice  Wraps the positions into ERC1155 tokens
abstract contract PositionManager is ManagerBase, ERC1155Permit {
    /// @dev  Ties together pool ids with engine addresses, this is necessary because
    ///       there is no way to get the Primitive Engine address from a pool id
    mapping(uint256 => address) private cache;

    /// @dev  Empty variable to pass to the _mint function
    bytes constant private _empty = "";

    /// @notice         Returns the metadata of a token
    /// @param tokenId  Token id to look for (same as pool id)
    /// @return         Metadata of the token as a string
    function uri(uint256 tokenId) public view override returns (string memory) {
        return IPositionDescriptor(positionDescriptor).getMetadata(cache[tokenId], tokenId);
    }

    /// @notice         Allocates {amount} of {poolId} liquidity to {account} balance
    /// @param account  Recipient of the liquidity
    /// @param engine   Address of the Primitive Engine
    /// @param poolId   Id of the pool
    /// @param amount   Amount of liquidity to allocate
    function _allocate(
        address account,
        address engine,
        bytes32 poolId,
        uint256 amount
    ) internal {
        _mint(account, uint256(poolId), amount, _empty);

        if (cache[uint256(poolId)] == address(0)) cache[uint256(poolId)] = engine;
    }

    /// @notice         Removes {amount} of {poolId} liquidity from {account} balance
    /// @param account  Account to remove from
    /// @param poolId   Id of the pool
    /// @param amount   Amount of liquidity to remove
    function _remove(
        address account,
        bytes32 poolId,
        uint256 amount
    ) internal {
        _burn(account, uint256(poolId), amount);
    }
}