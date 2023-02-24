// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";

contract Hasher is IHasher {
    /// @inheritdoc IHasher
    function packMessage(
        uint256 srcChainSlug_,
        address srcPlug_,
        uint256 dstChainSlug_,
        address dstPlug_,
        uint256 msgId_,
        uint256 msgGasLimit_,
        uint256 executionFee_,
        bytes calldata payload_
    ) external pure override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    srcChainSlug_,
                    srcPlug_,
                    dstChainSlug_,
                    dstPlug_,
                    msgId_,
                    msgGasLimit_,
                    executionFee_,
                    payload_
                )
            );
    }
}