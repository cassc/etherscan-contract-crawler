// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";

interface IGobDrops {
  function transferFrom(address from, address to, uint256 id) external;
}

contract GobDropsConsume is Owned {

    address public gobDrops;

    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor(address gobDropsAddress) Owned(msg.sender) {
      gobDrops = gobDropsAddress;
    }

    /// @dev Emitted when multiple tokens are consumed.
    event BulkConsume(
        uint indexed gooeyTokenId,
        uint[] gobDropTokenIds,
        address indexed caller
    );

    /// @dev Emitted when a single token is consumed.
    event SingleConsume(
        uint indexed gooeyTokenId,
        uint indexed gobDropTokenId,
        address indexed caller
    );

    /// @notice Function to consume multiple gobDrops for a single gobbler.
    /// @param gooeyTokenId The tokenId of the gobbler to consume gobDrops for.
    /// @param gobDropTokenIds The tokenIds of the gobDrops to consume.
    function bulkConsume(
        uint gooeyTokenId,
        uint[] calldata gobDropTokenIds
    ) external {
        for (uint i = 0; i < gobDropTokenIds.length; i++) {
            IGobDrops(gobDrops).transferFrom(msg.sender, DEAD_ADDRESS, gobDropTokenIds[i]);
        }
        emit BulkConsume(gooeyTokenId, gobDropTokenIds, msg.sender);
    }

    /// @notice Function to consume a single gobDrop for a single gobbler.
    /// @param gooeyTokenId The tokenId of the gobbler to consume gobDrops for.
    /// @param gobDropTokenId The tokenId of the gobDrop to consume.
    function singleConsume(
        uint gooeyTokenId,
        uint gobDropTokenId
    ) external {
        IGobDrops(gobDrops).transferFrom(msg.sender, DEAD_ADDRESS, gobDropTokenId);
        emit SingleConsume(gooeyTokenId, gobDropTokenId, msg.sender);
    }

    /// @notice Owner function to update the Gob Drops contract address.
    /// @param _gobDrops The new Gob Drops address.
    function updateGobDrops(address _gobDrops) external onlyOwner {
        gobDrops = _gobDrops;
    }

}