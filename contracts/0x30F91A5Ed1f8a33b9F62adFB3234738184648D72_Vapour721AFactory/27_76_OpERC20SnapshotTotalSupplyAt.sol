// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/// @title OpERC20SnapshotTotalSupplyAt
/// @notice Opcode for Open Zeppelin `ERC20Snapshot.totalSupplyAt`.
/// https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Snapshot
library OpERC20SnapshotTotalSupplyAt {
    /// Stack `totalSupplyAt`.
    function totalSupplyAt(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        uint256 location_;
        uint256 token_;
        uint256 snapshotId_;
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            location_ := sub(stackTopLocation_, 0x20)
            token_ := mload(location_)
            snapshotId_ := mload(stackTopLocation_)
        }
        uint256 totalSupply_ = ERC20Snapshot(address(uint160(token_)))
            .totalSupplyAt(snapshotId_);
        assembly {
            mstore(location_, totalSupply_)
        }
        return stackTopLocation_;
    }
}