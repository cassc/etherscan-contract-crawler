/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract Batcher {
    event Event(address wallet, string hash);

    function airdropERC1155s(IERC1155 token, address[] calldata wallets, uint256 tokenId) external {
        address from = msg.sender;
        for (uint256 i = 0; i < wallets.length; i++) {
            token.safeTransferFrom(from, wallets[i], tokenId, 1, "");
        }
    }
}