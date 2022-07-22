// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ItemType {
    Empty,      // 0
    Mainhand,   // 1
    Offhand,    // 2
    Pet         // 3
}

/// 288 bytes
struct Item {
    uint256 itemId;
    uint8 powerLevel;
    ItemType itemType;
}

/// ownerId is the tokenId of the nft that the item is being equipped to, this
/// nft essentially "owns" the item while it's held in the MagicFolk contract
function encodeOwnerIdAndItem(
    uint256 ownerId, 
    Item memory item
) pure returns (bytes memory) {
    // bytes memory _ownerId = abi.encodePacked(ownerId);
    // bytes memory _item = abi.encode(item);
    // return bytes.concat(_ownerId, _item);
    return abi.encode(ownerId, item);
}

function decodeOwnerIdAndItem(
    bytes calldata _data
) pure returns (uint256, Item memory) { 
    uint256 ownerId = abi.decode(_data[:32], (uint256));

    // Item memory item = abi.decode(_data[32:], (Item)); 
    // Life is pain...

    Item memory item;
    item.itemId = abi.decode(_data[32:64], (uint256));
    item.powerLevel = abi.decode(_data[64:96], (uint8));
    item.itemType = abi.decode(_data[96:], (ItemType));
    
    return (ownerId, item);
}

contract CommonConstants {
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
}