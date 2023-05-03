// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

/**
 * @notice Helper contract to facilitate batch transfers of ERC721 tokens.
 */
contract ERC721BatchTransfer {
    /**
     * @notice Transfers a batch of tokens owned by the caller to a single receiver.
     */
    function batchTransferFromSingleReceiver(IERC721 token, address to, uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; ++i) {
            token.transferFrom(msg.sender, to, tokenIds[i]);
        }
    }
}