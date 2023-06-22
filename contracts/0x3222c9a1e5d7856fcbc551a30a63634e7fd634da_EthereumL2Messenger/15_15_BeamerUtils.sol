// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library BeamerUtils {
    function createRequestId(
        uint256 sourceChainId,
        uint256 targetChainId,
        address targetTokenAddress,
        address targetReceiverAddress,
        uint256 amount,
        uint96 nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sourceChainId,
                    targetChainId,
                    targetTokenAddress,
                    targetReceiverAddress,
                    amount,
                    nonce
                )
            );
    }
}