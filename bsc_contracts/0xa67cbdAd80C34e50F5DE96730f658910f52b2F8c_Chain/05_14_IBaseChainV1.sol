// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseChainV1 {
    /// @dev number of blocks (consensus rounds) saved in this contract
    function blocksCount() external returns (uint32);

    /// @dev number of all blocks that were generated before switching to this contract
    /// please note, that there might be a gap of one block when we switching from old to new contract
    /// see constructor for details
    function blocksCountOffset() external returns (uint32);

    function getLatestBlockId() external view returns (uint32);

    function getBlockTimestamp(uint32 _blockId) external view returns (uint32);

    function getStatus() external view returns (
        uint256 blockNumber,
        uint16 timePadding,
        uint32 lastDataTimestamp,
        uint32 lastId,
        uint32 nextBlockId
    );
}