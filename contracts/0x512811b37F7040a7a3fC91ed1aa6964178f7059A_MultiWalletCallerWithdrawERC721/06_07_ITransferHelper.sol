// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ConduitItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}
struct TransferHelperItem {
    ConduitItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}
struct TransferHelperItemsWithRecipient {
    TransferHelperItem[] items;
    address recipient;
    bool validateERC721Receiver;
}